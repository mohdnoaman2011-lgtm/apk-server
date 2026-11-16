enum TunnelProvider { localhostRun, ngrok, custom }

/// إعدادات النفق. كل الأنواع تعمل عبر SSH (بدون ملفات تنفيذية إضافية):
///  • localhostRun: رابط عشوائي مؤقت (مجاني)
///  • ngrok:        نطاق ثابت مجاني من حساب ngrok
///  • custom:       خادمك الخاص (VPS) بنطاقك أنت
class TunnelConfig {
  TunnelConfig({
    this.provider = TunnelProvider.localhostRun,
    this.ngrokToken = '',
    this.ngrokDomain = '',
    this.host = '',
    this.port = 22,
    this.user = '',
    this.password = '',
    this.remotePort = 8080,
    this.publicUrl = '',
  });

  TunnelProvider provider;
  String ngrokToken;
  String ngrokDomain;
  String host;
  int port;
  String user;
  String password;
  int remotePort;
  String publicUrl;

  String get ngrokHost =>
      ngrokDomain.trim().replaceFirst(RegExp(r'^https?://'), '').replaceAll('/', '');

  bool get isValid => switch (provider) {
        TunnelProvider.localhostRun => true,
        TunnelProvider.ngrok => ngrokToken.trim().isNotEmpty && ngrokHost.isNotEmpty,
        TunnelProvider.custom =>
          host.trim().isNotEmpty && user.trim().isNotEmpty && publicUrl.trim().isNotEmpty,
      };

  String get label => switch (provider) {
        TunnelProvider.localhostRun => 'رابط مؤقت (localhost.run)',
        TunnelProvider.ngrok => 'رابط ثابت (ngrok)',
        TunnelProvider.custom => 'خادمي الخاص',
      };

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'ngrokToken': ngrokToken,
        'ngrokDomain': ngrokDomain,
        'host': host,
        'port': port,
        'user': user,
        'password': password,
        'remotePort': remotePort,
        'publicUrl': publicUrl,
      };

  factory TunnelConfig.fromJson(Map<String, dynamic> j) => TunnelConfig(
        provider: TunnelProvider.values.firstWhere(
          (e) => e.name == j['provider'],
          orElse: () => TunnelProvider.localhostRun,
        ),
        ngrokToken: (j['ngrokToken'] as String?) ?? '',
        ngrokDomain: (j['ngrokDomain'] as String?) ?? '',
        host: (j['host'] as String?) ?? '',
        port: (j['port'] as int?) ?? 22,
        user: (j['user'] as String?) ?? '',
        password: (j['password'] as String?) ?? '',
        remotePort: (j['remotePort'] as int?) ?? 8080,
        publicUrl: (j['publicUrl'] as String?) ?? '',
      );
}
