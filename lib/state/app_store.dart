import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/i18n.dart';
import '../core/net.dart';
import '../models/apk_app.dart';
import '../models/app_prefs.dart';
import '../models/tunnel_config.dart';
import '../services/apk_reader.dart';
import '../services/background.dart';
import '../services/storage.dart';

/// حالة الواجهة. السيرفر والنفق يعملان في خدمة الخلفية؛ هذا الكلاس يكتب
/// البيانات في الملفات ويرسل أمر reload ثم يستقبل الحالة من الخدمة.
class AppStore extends ChangeNotifier {
  static const port = kPort;

  final _storage = Storage();
  final apps = <ApkApp>[];

  // ── محفوظ ──
  bool serverOn = true;
  bool tunnelOn = false;
  TunnelConfig tunnelConfig = TunnelConfig();
  AppPrefs prefs = AppPrefs();

  // ── حالة قادمة من الخدمة ──
  String ip = '127.0.0.1';
  bool online = true;
  bool running = false;
  String? error;
  bool tunnelBusy = false;
  String? publicUrl;
  String? tunnelError;

  bool picking = false; // أثناء اختيار/نسخ ملف الـ APK
  Future<void> _saving = Future.value();

  ThemeMode get themeMode => switch (prefs.theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
  AppLang get lang => prefs.lang == 'en' ? AppLang.en : AppLang.ar;

  String link(ApkApp a) => 'http://$ip:$port/${a.token}';
  String? publicLink(ApkApp a) => publicUrl == null ? null : '$publicUrl/${a.token}';

  Future<void> init() async {
    await _storage.init();
    final data = await _storage.load();
    apps.addAll(data.apps);
    serverOn = data.serverOn;
    tunnelOn = data.tunnelOn;
    tunnelConfig = data.tunnelConfig;
    prefs = data.prefs;
    currentLang = lang;
    _applyDownloads(await _storage.loadDownloads());
    ip = (await readNet(ip)).ip;

    Background.init();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    if (serverOn) await _ensureService();
  }

  // ───────── الخدمة ─────────

  /// إن كانت الخدمة شغّالة (مثلاً بقيت بعد إغلاق الواجهة) نطلب منها الحالة، وإلا نشغّلها.
  Future<void> _ensureService() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask({'cmd': 'status'});
    } else {
      await Background.start();
    }
  }

  void _onTaskData(Object d) {
    if (d is! Map) return;
    switch (d['t']) {
      case 'status':
        running = d['running'] == true;
        online = d['online'] == true;
        ip = (d['ip'] as String?) ?? ip;
        publicUrl = d['publicUrl'] as String?;
        tunnelBusy = d['tunnelBusy'] == true;
        tunnelError = d['tunnelError'] as String?;
        error = d['serverError'] as String?;
      case 'downloads':
        _applyDownloads((d['map'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())));
      case 'stopped':
        serverOn = false;
        running = false;
        publicUrl = null;
    }
    notifyListeners();
  }

  void _applyDownloads(Map<String, int> m) {
    for (final a in apps) {
      a.downloads = m[a.token] ?? a.downloads;
    }
  }

  /// يحفظ البيانات ثم يطلب من الخدمة إعادة قراءتها (بالترتيب حتى لا تقرأ ملفاً قديماً).
  void _commit() {
    _saving = _saving.then((_) async {
      await _storage.save(apps, serverOn, tunnelOn, tunnelConfig, prefs);
      FlutterForegroundTask.sendDataToTask({'cmd': 'reload'});
    });
  }

  // ───────── الإعدادات ─────────

  Future<void> setServer(bool on) async {
    serverOn = on;
    notifyListeners();
    _commit();
    await _saving;
    if (on) {
      await _ensureService();
    } else {
      running = false;
      publicUrl = null;
      tunnelBusy = false;
      await Background.stop();
      notifyListeners();
    }
  }

  void setTunnel(bool on) {
    tunnelOn = on;
    notifyListeners();
    _commit();
  }

  /// يطلب من الخدمة إعادة محاولة فتح النفق.
  void retryTunnel() => FlutterForegroundTask.sendDataToTask({'cmd': 'reload'});

  void setTunnelConfig(TunnelConfig c) {
    tunnelConfig = c;
    notifyListeners();
    _commit();
  }

  void setThemeMode(ThemeMode m) {
    prefs.theme = m.name;
    notifyListeners();
    _commit();
  }

  void setLang(AppLang l) {
    prefs.lang = l.name;
    currentLang = l;
    notifyListeners();
    _commit();
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
      throw '${tr0('هذا الإصدار')} (${info.versionName}) ${tr0('مرفوع مسبقاً')}';
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
    _commit();
    notifyListeners();
    return app;
  }

  Future<void> removeApp(ApkApp a) async {
    apps.remove(a);
    for (final v in a.versions) {
      await _storage.deleteVersionFiles(v);
    }
    _commit();
    notifyListeners();
  }

  Future<void> removeVersion(ApkApp a, ApkVersion v) async {
    if (a.versions.length == 1) return removeApp(a);
    a.versions.remove(v);
    await _storage.deleteVersionFiles(v);
    _commit();
    notifyListeners();
  }

  void setEnabled(ApkApp a, bool on) {
    a.enabled = on;
    _commit();
    notifyListeners();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }
}

final store = AppStore();
