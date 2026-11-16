String fmtSize(int b) => b >= 1 << 20
    ? '${(b / (1 << 20)).toStringAsFixed(1)} MB'
    : '${(b / 1024).toStringAsFixed(0)} KB';

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
