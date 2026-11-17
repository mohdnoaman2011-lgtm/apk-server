import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/apk_app.dart';
import '../models/tunnel_config.dart';
import '../services/apk_reader.dart';
import '../services/background.dart';
import '../services/storage.dart';
import '../services/tunnel.dart';
import '../services/web_server.dart';

class AppStore extends ChangeNotifier {
  static const port = 8080;

  final _storage = Storage();
  late final WebServer _server;
  late final TunnelService _tunnel = TunnelService(port);
  final apps = <ApkApp>[];

  String ip = '127.0.0.1';
  bool online = true;
  bool serverOn = true; // اختيار المستخدم (محفوظ)
  String? error;
  bool picking = false; // أثناء اختيار/نسخ ملف الـ APK
  StreamSubscription<List<ConnectivityResult>>? _conn;

  // ── النفق (الوصول من الإنترنت) ──
  bool tunnelOn = false; // اختيار المستخدم (محفوظ)
  TunnelConfig tunnelConfig = TunnelConfig();
  bool tunnelBusy = false;
  String? publicUrl;
  String? tunnelError;
  int _tunnelGen = 0; // يُبطل نتائج المحاولات القديمة
  Timer? _retry;

  bool get running => _server.running;
  String link(ApkApp a) => 'http://$ip:$port/${a.token}';
  String? publicLink(ApkApp a) => publicUrl == null ? null : '$publicUrl/${a.token}';

  String get _statusText => !online
      ? 'لا يوجد اتصال – بانتظار الشبكة'
      : publicUrl != null
          ? 'عام: $publicUrl'
          : 'الرابط: $ip:$port';

  Future<void> init() async {
    await _storage.init();
    final data = await _storage.load();
    apps.addAll(data.apps);
    serverOn = data.serverOn;
    tunnelOn = data.tunnelOn;
    tunnelConfig = data.tunnelConfig;
    _server = WebServer(
      getApps: () => apps,
      onDownload: (a) {
        a.downloads++;
        _persist();
        notifyListeners();
      },
    );
    Background.init();
    await _refreshNetwork();
    _conn = Connectivity().onConnectivityChanged.listen(_onConnectivity);
    if (serverOn) {
      await _startAll();
      unawaited(_openTunnel());
    }
  }

  // ───────── الشبكة والسيرفر ─────────

  Future<void> _refreshNetwork() async {
    final r = await Connectivity().checkConnectivity();
    online = r.any((x) => x != ConnectivityResult.none);
    ip = await NetworkInfo().getWifiIP() ?? ip;
  }

  /// السيرفر يستمر ما دام الجهاز متصلاً: عند عودة الاتصال أو تغيّر الشبكة
  /// نُعيد ربط السيرفر بالعنوان الجديد ونعيد فتح النفق.
  Future<void> _onConnectivity(List<ConnectivityResult> r) async {
    final wasOnline = online;
    final oldIp = ip;
    await _refreshNetwork();
    if (serverOn && (wasOnline != online || oldIp != ip)) {
      if (online) {
        await _server.stop();
        await _startAll();
        await _closeTunnel();
        unawaited(_openTunnel());
      } else {
        await _closeTunnel();
        await Background.update(_statusText);
      }
    }
    notifyListeners();
  }

  Future<void> _startAll() async {
    try {
      error = null;
      await _server.start(port);
      await Background.start(_statusText);
    } catch (e) {
      error = 'تعذّر تشغيل السيرفر: $e';
    }
    notifyListeners();
  }

  Future<void> setServer(bool on) async {
    serverOn = on;
    if (on) {
      await _startAll();
      unawaited(_openTunnel());
    } else {
      await _closeTunnel();
      await _server.stop();
      await Background.stop();
    }
    _persist();
    notifyListeners();
  }

  // ───────── النفق ─────────

  Future<void> setTunnel(bool on) async {
    tunnelOn = on;
    _persist();
    if (on) {
      await _openTunnel();
    } else {
      await _closeTunnel();
      await Background.update(_statusText);
    }
    notifyListeners();
  }

  /// حفظ إعدادات النفق وإعادة فتحه بها إن كان مفعّلاً.
  Future<void> setTunnelConfig(TunnelConfig c) async {
    tunnelConfig = c;
    _persist();
    if (tunnelOn) {
      await _closeTunnel();
      unawaited(_openTunnel());
    }
    notifyListeners();
  }

  Future<void> _openTunnel() async {
    if (!tunnelOn || !serverOn || !online || tunnelBusy || publicUrl != null) return;
    final gen = ++_tunnelGen;
    tunnelBusy = true;
    tunnelError = null;
    notifyListeners();
    try {
      final r = await _tunnel.start(tunnelConfig);
      if (gen != _tunnelGen) {
        await _tunnel.stop(); // أُلغي الطلب أثناء الاتصال
        _scheduleRetry();
        return;
      }
      publicUrl = r.url;
      unawaited(r.closed.whenComplete(() => _onTunnelClosed(gen)));
      await Background.update(_statusText);
    } catch (e) {
      await _tunnel.stop();
      if (gen == _tunnelGen) {
        tunnelError = 'تعذّر فتح النفق: $e';
        _scheduleRetry();
      }
    } finally {
      tunnelBusy = false;
      notifyListeners();
    }
  }

  void _onTunnelClosed(int gen) {
    if (gen != _tunnelGen) return; // أغلقناه نحن عمداً
    publicUrl = null;
    notifyListeners();
    unawaited(Background.update(_statusText));
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    if (!tunnelOn || !serverOn || !online) return;
    _retry = Timer(const Duration(seconds: 10), _openTunnel);
  }

  Future<void> _closeTunnel() async {
    _tunnelGen++;
    _retry?.cancel();
    publicUrl = null;
    tunnelError = null;
    await _tunnel.stop();
  }

  void setPicking(bool v) {
    if (picking == v) return;
    picking = v;
    notifyListeners();
  }

  // ───────── التطبيقات ─────────

  Future<ApkApp> addApk(String srcPath, {String notes = ''}) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final tmpIcon = '${_storage.iconDir.path}/_$stamp.png';
    final info = await ApkReader.read(srcPath, tmpIcon);

    final existing = apps.where((a) => a.id == info.package).firstOrNull;
    if (existing != null && existing.versions.any((v) => v.versionCode == info.versionCode)) {
      await File(tmpIcon).delete();
      throw 'هذا الإصدار (${info.versionName}) مرفوع مسبقاً';
    }

    final apkPath = '${_storage.apkDir.path}/${info.package}-${info.versionCode}.apk';
    final iconPath = '${_storage.iconDir.path}/${info.package}-${info.versionCode}.png';
    final copied = await File(srcPath).copy(apkPath);
    await File(tmpIcon).rename(iconPath);

    final v = ApkVersion(
      versionName: info.versionName,
      versionCode: info.versionCode,
      size: await copied.length(),
      date: DateTime.now(),
      apkPath: apkPath,
      iconPath: iconPath,
      notes: notes,
    );

    final ApkApp app;
    if (existing != null) {
      existing.versions
        ..add(v)
        ..sort((a, b) => b.versionCode.compareTo(a.versionCode));
      if (identical(existing.versions.first, v)) existing.name = info.name;
      app = existing;
    } else {
      app = ApkApp(id: info.package, name: info.name, versions: [v]);
      apps.add(app);
    }
    _persist();
    notifyListeners();
    return app;
  }

  Future<void> removeApp(ApkApp a) async {
    apps.remove(a);
    for (final v in a.versions) {
      await _storage.deleteVersionFiles(v);
    }
    _persist();
    notifyListeners();
  }

  Future<void> removeVersion(ApkApp a, ApkVersion v) async {
    if (a.versions.length == 1) return removeApp(a);
    a.versions.remove(v);
    await _storage.deleteVersionFiles(v);
    _persist();
    notifyListeners();
  }

  void setEnabled(ApkApp a, bool on) {
    a.enabled = on;
    _persist();
    notifyListeners();
  }

  void _persist() => unawaited(_storage.save(apps, serverOn, tunnelOn, tunnelConfig));

  @override
  void dispose() {
    _retry?.cancel();
    _conn?.cancel();
    super.dispose();
  }
}

final store = AppStore();
