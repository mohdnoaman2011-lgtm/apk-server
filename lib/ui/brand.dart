import 'package:flutter/material.dart' hide Text;

import 'brand_assets.dart';
import 'theme.dart';

/// رمز الشعار الحقيقي (مضمَّن داخل الكود).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Image.memory(
        kMarkBytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      );
}

/// أيقونة داخل مربع ملوّن شفاف.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 40});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.cs.primary.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(size * .32),
        ),
        child: Icon(icon, size: size * .52, color: context.cs.primary),
      );
}

/// خلفية بطاقة الحالة الرئيسية (تدرّج بألوان الشعار).
BoxDecoration heroDecoration(BuildContext context) => BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: context.isDark
            ? const [Color(0xFF0F4A55), Color(0xFF0C2B4A)]
            : const [Color(0xFFD9F7F1), Color(0xFFDDEBFA)],
      ),
      border: Border.all(color: context.isDark ? const Color(0x3322E5C0) : const Color(0x330A7C70)),
    );
