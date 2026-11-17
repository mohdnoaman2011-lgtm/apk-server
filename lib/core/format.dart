/// يعزل النص (أرقام/إنجليزي) كي لا يختلط ترتيبه داخل جملة عربية.
String ltr(String s) => '\u2066$s\u2069';

String fmtSize(int b) => b >= 1 << 20
    ? '${(b / (1 << 20)).toStringAsFixed(1)} MB'
    : '${(b / 1024).toStringAsFixed(0)} KB';

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
