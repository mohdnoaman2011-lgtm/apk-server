import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/apk_app.dart';
import '../models/app_prefs.dart';
import '../models/tunnel_config.dart';

/// تخزين دائم: ملف JSON للبيانات + مجلدات للـ APK والأيقونات.
class Storage {
  late final Directory apkDir;
  late final Directory iconDir;
  late final File _db;
  late final File _dl;

  Future<void> init() async {
    final root = await getApplicationDocumentsDirectory();
    apkDir = Directory('${root.path}/apks')..createSync(recursive: true);
    iconDir = Directory('${root.path}/icons')..createSync(recursive: true);
    _db = File('${root.path}/apps.json');
    _dl = File('${root.path}/downloads.json');
  }

  Future<({List<ApkApp> apps, bool serverOn, bool tunnelOn, TunnelConfig tunnelConfig, AppPrefs prefs})> load() async {
    try {
      if (!_db.existsSync()) return (apps: <ApkApp>[], serverOn: true, tunnelOn: false, tunnelConfig: TunnelConfig(), prefs: AppPrefs());
      final j = jsonDecode(await _db.readAsString()) as Map<String, dynamic>;
      final apps = (j['apps'] as List)
          .map((a) => ApkApp.fromJson(a as Map<String, dynamic>))
          .where((a) => a.versions.isNotEmpty)
          .toList();
      return (
        apps: apps,
        serverOn: (j['serverOn'] as bool?) ?? true,
        tunnelOn: (j['tunnelOn'] as bool?) ?? false,
        tunnelConfig: TunnelConfig.fromJson((j['tunnel'] as Map<String, dynamic>?) ?? {}),
        prefs: AppPrefs.fromJson((j['prefs'] as Map<String, dynamic>?) ?? {}),
      );
    } catch (_) {
      return (apps: <ApkApp>[], serverOn: true, tunnelOn: false, tunnelConfig: TunnelConfig(), prefs: AppPrefs());
    }
  }

  Future<void> save(List<ApkApp> apps, bool serverOn, bool tunnelOn, TunnelConfig tunnelConfig, AppPrefs prefs) async {
    final tmp = File('${_db.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await tmp.writeAsString(jsonEncode({
      'serverOn': serverOn,
      'tunnelOn': tunnelOn,
      'tunnel': tunnelConfig.toJson(),
      'prefs': prefs.toJson(),
      'apps': apps.map((a) => a.toJson()).toList(),
    }));
    await tmp.rename(_db.path); // كتابة آمنة حتى لا يتلف الملف عند الإغلاق المفاجئ
  }

  /// عدّاد التحميلات: تكتبه خدمة الخلفية فقط، والواجهة تقرأه (لا تعارض بين العمليتين).
  Future<Map<String, int>> loadDownloads() async {
    try {
      if (!_dl.existsSync()) return {};
      final j = jsonDecode(await _dl.readAsString()) as Map<String, dynamic>;
      return j.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDownloads(Map<String, int> m) async {
    final tmp = File('${_dl.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await tmp.writeAsString(jsonEncode(m));
    await tmp.rename(_dl.path);
  }

  /// يُستدعى من زر "إيقاف" في الإشعار حين تكون الواجهة مغلقة.
  Future<void> setServerOn(bool v) async {
    try {
      final j = jsonDecode(await _db.readAsString()) as Map<String, dynamic>;
      j['serverOn'] = v;
      final tmp = File('${_db.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
      await tmp.writeAsString(jsonEncode(j));
      await tmp.rename(_db.path);
    } catch (_) {}
  }

  Future<void> deleteVersionFiles(ApkVersion v) async {
    for (final p in [v.apkPath, v.iconPath]) {
      try {
        final f = File(p);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
  }
}
