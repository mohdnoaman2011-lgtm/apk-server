import 'package:flutter/widgets.dart' as w;
import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget, StatelessWidget, TextOverflow, TextAlign, TextStyle, Widget, Key;

import '../core/i18n.dart';

export '../core/i18n.dart';

/// يوفّر اللغة الحالية للشجرة؛ تتغيّر اللغة فتُعاد رسم كل النصوص المعتمدة عليه.
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});
  final AppLang lang;

  static AppLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ?? currentLang;

  @override
  bool updateShouldNotify(LangScope old) => old.lang != lang;
}

String tr(BuildContext context, String ar) => trLang(LangScope.of(context), ar);

/// بديل لـ Text يترجم النص العربي تلقائياً حسب لغة التطبيق.
class Text extends StatelessWidget {
  const Text(this.data, {super.key, this.style, this.maxLines, this.overflow, this.textAlign});
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => w.Text(
        tr(context, data),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
}
