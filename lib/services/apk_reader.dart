import 'package:flutter/services.dart';

import '../core/i18n.dart';

class ApkInfo {
  ApkInfo(this.name, this.package, this.versionName, this.versionCode);
  final String name;
  final String package;
  final String versionName;
  final int versionCode;
}

/// يقرأ بيانات ملف APK الحقيقية (الاسم، الحزمة، الإصدار، الأيقونة) عبر كود Android الأصلي.
class ApkReader {
  static const _channel = MethodChannel('apk_reader');

  /// يحفظ الأيقونة كصورة PNG في [iconOut] ويعيد بيانات التطبيق.
  static Future<ApkInfo> read(String apkPath, String iconOut) async {
    final m = await _channel.invokeMapMethod<String, dynamic>(
      'read',
      {'path': apkPath, 'iconOut': iconOut},
    );
    if (m == null) throw tr0('تعذّرت قراءة الملف');
    return ApkInfo(
      m['name'] as String,
      m['package'] as String,
      m['versionName'] as String,
      (m['versionCode'] as num).toInt(),
    );
  }
}
