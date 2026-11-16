import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../models/tunnel_config.dart';
import '../../state/app_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tunnel_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget tunnelSub = store.tunnelBusy
        ? const Text('جارٍ فتح النفق…')
        : store.publicUrl != null
            ? LtrText(store.publicUrl!, style: const TextStyle(color: kGreen))
            : store.tunnelError != null
                ? Text(store.tunnelError!, style: const TextStyle(color: Colors.redAccent))
                : const Text('ينشئ رابط https عاماً يعمل من أي شبكة.');

    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('الإعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: SwitchListTile(
          title: const Text('تشغيل السيرفر'),
          subtitle: LtrText('${store.ip}:${AppStore.port}'),
          value: store.serverOn,
          onChanged: store.setServer,
        ),
      ),
      Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.public_rounded),
          title: const Text('الوصول من الإنترنت (نفق)'),
          subtitle: tunnelSub,
          value: store.tunnelOn,
          onChanged: store.serverOn ? store.setTunnel : null,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.tune_rounded),
          title: const Text('نوع النفق'),
          subtitle: Text(store.tunnelConfig.label),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TunnelSettingsPage()),
          ),
        ),
      ),
      if (store.tunnelConfig.provider == TunnelProvider.localhostRun)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('الرابط المؤقت'),
            subtitle: Text('يتغيّر عند كل إعادة اتصال. للحصول على رابط ثابت اختر ngrok أو خادمك الخاص من "نوع النفق".'),
          ),
        ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.lock_outline_rounded),
          title: Text('تنبيه'),
          subtitle: Text('أي شخص لديه رابط تطبيق يستطيع تنزيله، فعطّل الرابط من صفحة التطبيق عند الحاجة. بيانات النفق تُحفظ داخل مجلد التطبيق الخاص.'),
        ),
      ),
      Card(
        child: ListTile(
          leading: Icon(store.online ? Icons.wifi_rounded : Icons.wifi_off_rounded),
          title: Text(store.online ? 'الجهاز متصل بالشبكة' : 'لا يوجد اتصال'),
          subtitle: const Text('يعمل السيرفر في الخلفية ما دام الجهاز متصلاً، ويُعاد ربطه تلقائياً عند تغيّر الشبكة.'),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.battery_saver_rounded),
          title: const Text('السماح بالعمل في الخلفية'),
          subtitle: const Text('استثناء التطبيق من توفير البطارية حتى لا يوقفه النظام.'),
          onTap: FlutterForegroundTask.requestIgnoreBatteryOptimization,
        ),
      ),
    ]);
  }
}
