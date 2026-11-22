import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';

import '../../models/tunnel_config.dart';
import '../../state/app_store.dart';
import '../theme.dart';

class TunnelSettingsPage extends StatefulWidget {
  const TunnelSettingsPage({super.key});
  @override
  State<TunnelSettingsPage> createState() => _TunnelSettingsPageState();
}

class _TunnelSettingsPageState extends State<TunnelSettingsPage> {
  final c = store.tunnelConfig;
  late TunnelProvider provider = c.provider;
  late final token = TextEditingController(text: c.ngrokToken);
  late final domain = TextEditingController(text: c.ngrokDomain);
  late final host = TextEditingController(text: c.host);
  late final port = TextEditingController(text: '${c.port}');
  late final user = TextEditingController(text: c.user);
  late final pass = TextEditingController(text: c.password);
  late final remotePort = TextEditingController(text: '${c.remotePort}');
  late final publicUrl = TextEditingController(text: c.publicUrl);

  Widget _field(TextEditingController ctl, String label,
      {bool secret = false, bool number = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: ctl,
          obscureText: secret,
          keyboardType: number ? TextInputType.number : TextInputType.url,
          decoration: InputDecoration(labelText: tr(context, label), hintText: hint, border: const OutlineInputBorder()),
        ),
      ),
    );
  }

  Widget _help(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.8)),
      );

  void _save() {
    final cfg = TunnelConfig(
      provider: provider,
      ngrokToken: token.text,
      ngrokDomain: domain.text,
      host: host.text,
      port: int.tryParse(port.text) ?? 22,
      user: user.text,
      password: pass.text,
      remotePort: int.tryParse(remotePort.text) ?? 8080,
      publicUrl: publicUrl.text,
    );
    if (!cfg.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل الحقول المطلوبة')));
      return;
    }
    store.setTunnelConfig(cfg);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات النفق')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SegmentedButton<TunnelProvider>(
          segments: const [
            ButtonSegment(value: TunnelProvider.localhostRun, label: Text('مؤقت 1')),
            ButtonSegment(value: TunnelProvider.pinggy, label: Text('مؤقت 2')),
            ButtonSegment(value: TunnelProvider.ngrok, label: Text('ngrok')),
            ButtonSegment(value: TunnelProvider.custom, label: Text('خادمي')),
          ],
          selected: {provider},
          onSelectionChanged: (s) => setState(() => provider = s.first),
        ),
        const SizedBox(height: 20),
        if (provider == TunnelProvider.localhostRun)
          _help('رابط عشوائي مجاني يتغيّر عند كل إعادة اتصال. لا يحتاج أي إعداد.'),
        if (provider == TunnelProvider.pinggy)
          _help('رابط مؤقت عبر المنفذ 443، جرّبه إن كان المنفذ 22 محظوراً على شبكتك (تحظره بعض الشبكات وشركات الاتصالات).'),
        if (provider == TunnelProvider.ngrok) ...[
          _help('رابط ثابت مجاني:\n'
              '١) أنشئ حساباً على ngrok.com\n'
              '٢) انسخ Authtoken من صفحة Your Authtoken\n'
              '٣) من صفحة Domains أنشئ نطاقك الثابت المجاني وانسخه'),
          _field(token, 'Authtoken', secret: true),
          _field(domain, 'النطاق الثابت', hint: 'name.ngrok-free.app'),
        ],
        if (provider == TunnelProvider.custom) ...[
          _help('لخادم VPS تملكه ونطاق خاص بك (رابط ثابت بالكامل).\n'
              'على الخادم ثبّت Caddy مثلاً وأضف:\n'
              'example.com { reverse_proxy 127.0.0.1:8080 }\n'
              'ثم أدخل بيانات SSH، ومنفذ التوجيه يجب أن يطابق المنفذ أعلاه.'),
          _field(host, 'عنوان الخادم', hint: 'vps.example.com'),
          _field(port, 'منفذ SSH', number: true),
          _field(user, 'اسم المستخدم'),
          _field(pass, 'كلمة المرور', secret: true),
          _field(remotePort, 'منفذ التوجيه على الخادم', number: true),
          _field(publicUrl, 'الرابط العام', hint: 'https://example.com'),
        ],
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ]),
    );
  }
}
