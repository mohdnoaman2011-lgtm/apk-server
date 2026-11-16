import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/apk_app.dart';
import '../state/app_store.dart';
import 'theme.dart';

/// أيقونة التطبيق الحقيقية المستخرجة من ملف الـ APK.
class AppIcon extends StatelessWidget {
  const AppIcon(this.app, {super.key, this.size = 44});
  final ApkApp app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size * .28);
    final f = File(app.current.iconPath);
    if (f.existsSync()) {
      return ClipRRect(
        borderRadius: r,
        child: Image.file(f, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kGreen, borderRadius: r),
      child: Text(app.name.characters.first,
          style: TextStyle(color: kBg, fontWeight: FontWeight.w700, fontSize: size * .45)),
    );
  }
}

class LtrText extends StatelessWidget {
  const LtrText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(text, style: style),
      );
}

void copyLink(BuildContext context, String link) {
  Clipboard.setData(ClipboardData(text: link));
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final (color, label) = !store.running
        ? (Colors.redAccent, 'متوقف')
        : !store.online
            ? (Colors.orangeAccent, 'لا يوجد اتصال')
            : (kGreen, 'السيرفر يعمل');
    return Chip(avatar: Icon(Icons.circle, size: 10, color: color), label: Text(label));
  }
}
