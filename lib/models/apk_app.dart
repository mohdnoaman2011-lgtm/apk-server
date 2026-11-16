import 'dart:math';

/// رمز عشوائي في الرابط العام حتى لا يمكن تخمين روابط التطبيقات.
String newToken() {
  const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
  final r = Random.secure();
  return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
}

class ApkVersion {
  ApkVersion({
    required this.versionName,
    required this.versionCode,
    required this.size,
    required this.date,
    required this.apkPath,
    required this.iconPath,
    this.notes = '',
  });

  final String versionName;
  final int versionCode;
  final int size;
  final DateTime date;
  final String apkPath;
  final String iconPath;
  final String notes;

  Map<String, dynamic> toJson() => {
        'versionName': versionName,
        'versionCode': versionCode,
        'size': size,
        'date': date.toIso8601String(),
        'apkPath': apkPath,
        'iconPath': iconPath,
        'notes': notes,
      };

  factory ApkVersion.fromJson(Map<String, dynamic> j) => ApkVersion(
        versionName: j['versionName'] as String,
        versionCode: j['versionCode'] as int,
        size: j['size'] as int,
        date: DateTime.parse(j['date'] as String),
        apkPath: j['apkPath'] as String,
        iconPath: j['iconPath'] as String,
        notes: (j['notes'] as String?) ?? '',
      );
}

/// التطبيق يُعرَّف باسم الحزمة (package) فيصبح رفع نفس الحزمة إصداراً جديداً تلقائياً.
class ApkApp {
  ApkApp({
    required this.id,
    required this.name,
    required this.versions,
    this.downloads = 0,
    this.enabled = true,
    String? token,
  }) : token = token ?? newToken();

  final String id; // package name
  final String token; // يُستخدم في الرابط
  String name;
  final List<ApkVersion> versions; // الأحدث أولاً
  int downloads;
  bool enabled;

  ApkVersion get current => versions.first;

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'name': name,
        'downloads': downloads,
        'enabled': enabled,
        'versions': versions.map((v) => v.toJson()).toList(),
      };

  factory ApkApp.fromJson(Map<String, dynamic> j) => ApkApp(
        id: j['id'] as String,
        token: j['token'] as String?,
        name: j['name'] as String,
        downloads: (j['downloads'] as int?) ?? 0,
        enabled: (j['enabled'] as bool?) ?? true,
        versions: (j['versions'] as List)
            .map((v) => ApkVersion.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}
