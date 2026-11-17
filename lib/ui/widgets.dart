import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/apk_app.dart';
import '../state/app_store.dart';
import 'theme.dart';

/// أيقونة التطبيق الحقيقية المستخرجة من ملف الـ APK.
/// بدون existsSync داخل build (كانت تسبب بطئاً عند كل إعادة رسم).
class AppIcon extends StatelessWidget {
  const AppIcon(this.app, {super.key, this.size = 44});
  final ApkApp app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size * .28);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: kGreen,
      child: Text(app.name.characters.first,
          style: TextStyle(color: kBg, fontWeight: FontWeight.w700, fontSize: size * .45)),
    );
    return ClipRRect(
      borderRadius: r,
      child: Image.file(
        File(app.current.iconPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}
