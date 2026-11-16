import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/apk_app.dart';
import '../models/tunnel_config.dart';

/// تخزين دائم: ملف JSON للبيانات + مجلدات للـ APK والأيقونات.
class Storage {
  late final Directory apkDir;
  late final Directory iconDir;
  late final File _db;

  Future<void> init() async {
    final root = await getApplicationDocumentsDirectory();
    apkDir = Directory('${root.path}/apks')..createSync(recursive: true);
    iconDir = Directory('${root.path}/icons')..createSync(recursive: true);
    _db = File('${root.path}/apps.json');
  }

  Future<({List<ApkApp> apps, bool serverOn, bool tunnelOn, TunnelConfig tunnelConfig})> load() async {
    try {
      if (!_db.existsSync()) return (apps: <ApkApp>[], serverOn: true, tunnelOn: false, tunnelConfig: TunnelConfig());
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
      );
    } catch (_) {
      return (apps: <ApkApp>[], serverOn: true, tunnelOn: false, tunnelConfig: TunnelConfig());
    }
  }

  Future<void> save(List<ApkApp> apps, bool serverOn, bool tunnelOn, TunnelConfig tunnelConfig) async {
    final tmp = File('${_db.path}.tmp');
    await tmp.writeAsString(jsonEncode({
      'serverOn': serverOn,
      'tunnelOn': tunnelOn,
      'tunnel': tunnelConfig.toJson(),
      'apps': apps.map((a) => a.toJson()).toList(),
    }));
    await tmp.rename(_db.path); // كتابة آمنة حتى لا يتلف الملف عند الإغلاق المفاجئ
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
