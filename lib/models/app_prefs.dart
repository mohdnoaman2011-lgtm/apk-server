/// تفضيلات العرض: المظهر (dark/light/system) واللغة (ar/en).
class AppPrefs {
  AppPrefs({this.theme = 'system', this.lang = 'ar'});
  String theme;
  String lang;

  Map<String, dynamic> toJson() => {'theme': theme, 'lang': lang};

  factory AppPrefs.fromJson(Map<String, dynamic> j) => AppPrefs(
        theme: (j['theme'] as String?) ?? 'system',
        lang: (j['lang'] as String?) ?? 'ar',
      );
}
