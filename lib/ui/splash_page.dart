import 'package:flutter/material.dart' hide Text;

import 'i18n.dart';
import 'theme.dart';

/// شاشة البداية: الشعار يظهر بتكبير ناعم، ثم الاسم، مع شريط تقدّم رفيع.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();
  late final Animation<double> _logo =
      CurvedAnimation(parent: _c, curve: const Interval(0, .55, curve: Curves.easeOutBack));
  late final Animation<double> _text =
      CurvedAnimation(parent: _c, curve: const Interval(.4, .85, curve: Curves.easeOut));
  late final Animation<double> _glow = CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(alignment: Alignment.center, children: [
        // توهّج نعناعي خلف الشعار
        AnimatedBuilder(
          animation: _glow,
          builder: (_, __) => Opacity(
            opacity: _glow.value,
            child: Container(
              width: 460,
              height: 460,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x3322E5C0), Color(0x0022E5C0)]),
              ),
            ),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: _logo.drive(Tween(begin: 0.0, end: 1.0)),
            child: ScaleTransition(
              scale: Tween<double>(begin: .8, end: 1).animate(_logo),
              child: Image.asset(
                'assets/mark.png',
                width: 210,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.dns_rounded, size: 120, color: kGreen),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _text,
            child: Column(children: [
              Image.asset(
                'assets/wordmark.png',
                width: 190,
                errorBuilder: (_, __, ___) => const Text(
                  'Apk Server',
                  style: TextStyle(color: kGreen, fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              const Text('خادم تطبيقاتك الشخصي', style: TextStyle(color: kMuted, fontSize: 14)),
            ]),
          ),
        ]),
        Positioned(
          bottom: 64,
          left: 72,
          right: 72,
          child: FadeTransition(
            opacity: _text,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(
                minHeight: 3,
                color: kGreen,
                backgroundColor: Color(0x1FFFFFFF),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
