import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/i18n.dart';
import '../core/net.dart';
import '../models/apk_app.dart';
import '../models/tunnel_config.dart';
import 'storage.dart';
import 'tunnel.dart';
import 'web_server.dart';

/// يعمل داخل عزل (isolate) خدمة الخلفية، فيبقى السيرفر والنفق شغّالين
/// حتى بعد إغلاق واجهة التطبيق. الواجهة تكتب البيانات في الملفات
/// وترسل أمر reload، والخدمة تقرؤها وتطبّقها وترسل الحالة للواجهة.
class ServerRuntime {
  final _storage = Storage();
  late final WebServer _server = WebServer(getApps: () => apps, onDownload: _onDownload);
  late final _tunnel = TunnelService(kPort, onLog: _addLog);
  final List<String> _logLines = [];
  void Function(Map<String, dynamic>) _emit = (_) {};

  List<ApkApp> apps = [];
  Map<String, int> _downloads = {};
  bool serverOn = true;
  bool tunnelOn = false;
  TunnelConfig tunnelConfig = TunnelConfig();
  String ip = '127.0.0.1';
  bool online = true;
  String? publicUrl;
  String? tunnelError;
  String? serverError;
  bool tunnelBusy = false;
  int _gen = 0;
  Timer? _retry;

  String get _statusText => !online
      ? tr0('لا يوجد اتصال – بانتظار الشبكة')
      : publicUrl != null
          ? '${tr0('عام')}: $publicUrl'
          : '${tr0('الرابط')}: $ip:$kPort';

  Future<void> init(void Function(Map<String, dynamic>) emit) async {
    _emit = emit;
    await _storage.init();
    _downloads = await _storage.loadDownloads();
    await reload();
  }

  /// يقرأ البيانات التي كتبتها الواجهة ويطبّقها.
  Future<void> reload() async {
    final d = await _storage.load();
    apps = d.apps;
    for (final a in apps) {
      a.downloads = _downloads[a.token] ?? a.downloads;
    }
    final oldCfg = jsonEncode(tunnelConfig.toJson());
    serverOn = d.serverOn;
    tunnelOn = d.tunnelOn;
    tunnelConfig = d.tunnelConfig;
    currentLang = d.prefs.lang == 'en' ? AppLang.en : AppLang.ar;
    final cfgChanged = oldCfg != jsonEncode(tunnelConfig.toJson());

    await _refreshNet();
    await _applyServer();
    if (!serverOn || !tunnelOn || cfgChanged) await _closeTunnel();
    if (serverOn && tunnelOn) unawaited(_openTunnel());
    await _notify();
    _emitStatus();
  }

  /// فحص دوري: تغيّر الشبكة أو انقطاع النفق.
  Future<void> tick() async {
    final oldIp = ip, wasOnline = online;
    await _refreshNet();
    if (serverOn && (oldIp != ip || wasOnline != online)) {
      if (online) {
        await _server.stop();
        await _applyServer();
        await _closeTunnel();
        unawaited(_openTunnel());
      } else {
        await _closeTunnel();
      }
      await _notify();
      _emitStatus();
    } else if (serverOn && tunnelOn && online && publicUrl == null && !tunnelBusy && _retry == null) {
      unawaited(_openTunnel());
    }
  }

  Future<void> handle(Map data) async {
    final cmd = data['cmd'];
    if (cmd == 'reload') {
      await reload();
    } else if (cmd == 'status') {
      _emitStatus();
      _emit({'t': 'log', 'lines': _logLines});
      _emit({'t': 'downloads', 'map': _downloads});
    }
  }

  /// زر "إيقاف" في الإشعار.
  Future<void> requestStop() async {
    await _storage.setServerOn(false);
    _emit({'t': 'stopped'});
    await FlutterForegroundTask.stopService();
  }

  Future<void> dispose() async {
    _retry?.cancel();
    await _closeTunnel();
    await _server.stop();
  }

  // ───────── داخلي ─────────

  Future<void> _refreshNet() async {
    final n = await readNet(ip);
    online = n.online;
    ip = n.ip;
  }

  Future<void> _applyServer() async {
    try {
      serverError = null;
      if (serverOn) {
        await _server.start(kPort);
      } else {
        await _server.stop();
      }
    } catch (e) {
      serverError = '${tr0('تعذّر تشغيل السيرفر')}: $e';
    }
  }

  void _onDownload(ApkApp a) {
    final n = (_downloads[a.token] ?? a.downloads) + 1;
    _downloads[a.token] = n;
    a.downloads = n;
    unawaited(_storage.saveDownloads(_downloads));
    _emit({'t': 'downloads', 'map': _downloads});
  }

  Future<void> _openTunnel() async {
    if (!tunnelOn || !serverOn || !online || tunnelBusy || publicUrl != null) return;
    final gen = ++_gen;
    tunnelBusy = true;
    tunnelError = null;
    _emitStatus();
    try {
      final r = await _tunnel.start(tunnelConfig).timeout(
        const Duration(seconds: 80),
        onTimeout: () => throw tr0('انتهت مهلة الاتصال بخادم النفق'),
      );
      if (gen != _gen) {
        await _tunnel.stop(); // أُلغي الطلب أثناء الاتصال
        _scheduleRetry();
        return;
      }
      publicUrl = r.url;
      unawaited(r.closed.whenComplete(() => _onClosed(gen)));
      await _notify();
    } catch (e) {
      await _tunnel.stop();
      if (gen == _gen) {
        tunnelError = '${tr0('تعذّر فتح النفق')}: $e';
        _scheduleRetry();
      }
    } finally {
      tunnelBusy = false;
      _emitStatus();
    }
  }

  void _onClosed(int gen) {
    if (gen != _gen) return; // أغلقناه نحن عمداً
    publicUrl = null;
    _emitStatus();
    unawaited(_notify());
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = null;
    if (!tunnelOn || !serverOn || !online) return;
    _retry = Timer(const Duration(seconds: 10), () {
      _retry = null;
      unawaited(_openTunnel());
    });
  }

  Future<void> _closeTunnel() async {
    _gen++;
    _retry?.cancel();
    _retry = null;
    publicUrl = null;
    tunnelError = null;
    await _tunnel.stop();
  }

  Future<void> _notify() async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: tr0('سيرفري يعمل'),
        notificationText: _statusText,
        notificationButtons: [NotificationButton(id: 'stop', text: tr0('إيقاف'))],
      );
    } catch (_) {}
  }

  void _addLog(String m) {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    _logLines.add('[${two(n.hour)}:${two(n.minute)}:${two(n.second)}] $m');
    if (_logLines.length > 80) _logLines.removeAt(0);
    _emit({'t': 'log', 'lines': List<String>.from(_logLines)});
  }

  void _emitStatus() => _emit({
        't': 'status',
        'running': _server.running,
        'online': online,
        'ip': ip,
        'publicUrl': publicUrl,
        'tunnelBusy': tunnelBusy,
        'tunnelError': tunnelError,
        'serverError': serverError,
      });
}
