import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'brand_assets.dart';
import 'i18n.dart';
import 'theme.dart';

/// شاشة البداية: خلفية متدرّجة بنقاط خفيفة، الشعار الحقيقي بتوهّج وحلقة دوّارة،
/// الاسم والوصف، ثم حالة التحميل وشريط تقدّم والإصدار.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  late final Animation<double> _logo =
      CurvedAnimation(parent: _in, curve: const Interval(0, .5, curve: Curves.easeOutBack));
  late final Animation<double> _fadeLogo =
      CurvedAnimation(parent: _in, curve: const Interval(0, .35, curve: Curves.easeOut));
  late final Animation<double> _text =
      CurvedAnimation(parent: _in, curve: const Interval(.35, .75, curve: Curves.easeOut));
  late final Animation<double> _bottom =
      CurvedAnimation(parent: _in, curve: const Interval(.55, 1, curve: Curves.easeOut));

  @override
  void dispose() {
    _in.dispose();
    _spin.dispose();
    super.dispose();
  }

  String get _status {
    final v = _in.value;
    if (v < .35) return 'جارٍ التهيئة…';
    if (v < .8) return 'تشغيل الخدمة…';
    return 'جاهز';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        // خلفية: تدرّج + نقاط خفيفة
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1830), Color(0xFF0B1F3A), Color(0xFF0A2A3C)],
              ),
            ),
            child: CustomPaint(painter: _DotsPainter()),
          ),
        ),
        // توهّج خلف الشعار
        Align(
          alignment: const Alignment(0, -.22),
          child: FadeTransition(
            opacity: _fadeLogo,
            child: Container(
              width: 520,
              height: 520,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x3322E5C0), Color(0x0022E5C0)]),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 5),
            SizedBox(
              width: 270,
              height: 270,
              child: Stack(alignment: Alignment.center, children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_spin, _fadeLogo]),
                  builder: (_, __) => Opacity(
                    opacity: _fadeLogo.value,
                    child: CustomPaint(size: const Size(270, 270), painter: _RingPainter(_spin.value)),
                  ),
                ),
                FadeTransition(
                  opacity: _fadeLogo,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .78, end: 1).animate(_logo),
                    child: Image.memory(kMarkBytes, width: 190, gaplessPlayback: true, filterQuality: FilterQuality.high),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            FadeTransition(
              opacity: _text,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, .25), end: Offset.zero).animate(_text),
                child: Column(children: [
                  Image.memory(kWordmarkBytes, width: 210, gaplessPlayback: true, filterQuality: FilterQuality.high),
                  const SizedBox(height: 12),
                  const Text('خادم تطبيقاتك الشخصي', style: TextStyle(color: kMuted, fontSize: 15)),
                ]),
              ),
            ),
            const Spacer(flex: 6),
            FadeTransition(
              opacity: _bottom,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(64, 0, 64, 0),
                child: Column(children: [
                  AnimatedBuilder(
                    animation: _in,
                    builder: (_, __) => Text(_status, style: const TextStyle(color: kMuted, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _in,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: Curves.easeInOut.transform(_in.value),
                        minHeight: 4,
                        color: kGreen,
                        backgroundColor: const Color(0x1FFFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('v1.0.0', style: TextStyle(color: Color(0x668CA2C2), fontSize: 12, letterSpacing: 1)),
                ]),
              ),
            ),
            const SizedBox(height: 28),
          ]),
        ),
      ]),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x0DFFFFFF);
    for (double y = 18; y < size.height; y += 30) {
      for (double x = 18; x < size.width; x += 30) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// حلقة رفيعة دوّارة حول الشعار.
class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x1F22E5C0);
    canvas.drawCircle(c, r, base);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6
      ..shader = SweepGradient(
        colors: const [Color(0x0022E5C0), Color(0xFF22E5C0)],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(rect);
    canvas.drawArc(rect, t * 2 * math.pi, math.pi * .9, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}
