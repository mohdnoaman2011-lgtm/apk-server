import 'package:flutter/material.dart' hide Text;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../models/tunnel_config.dart';
import '../../state/app_store.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tunnel_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _group(BuildContext context, IconData icon, String title, Widget control) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: context.cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: control),
          ]),
        ),
      );

  void _showLog(BuildContext context) {
    final text = store.tunnelLog.isEmpty ? tr(context, 'لا توجد سجلات بعد') : store.tunnelLog.join('\n');
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('سجل النفق'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(text, style: const TextStyle(fontSize: 12, height: 1.5)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => copyLink(c, text),
            child: const Text('نسخ'),
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final Widget tunnelSub = store.tunnelBusy
        ? const Text('جارٍ فتح النفق…')
        : store.publicUrl != null
            ? LtrText(store.publicUrl!, style: TextStyle(color: context.cs.primary))
            : store.tunnelError != null
                ? Text(store.tunnelError!, style: TextStyle(color: context.cs.error))
                : const Text('ينشئ رابط https عاماً يعمل من أي شبكة.');

    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('الإعدادات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: SwitchListTile(
          title: const Text('تشغيل السيرفر'),
          subtitle: Text(store.running ? 'يعمل الآن' : 'متوقف'),
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
          trailing: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TunnelSettingsPage()),
          ),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('سجل النفق'),
          subtitle: const Text('تتبّع مراحل الاتصال لمعرفة سبب الفشل'),
          trailing: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
          onTap: () => _showLog(context),
        ),
      ),
      _group(
        context,
        Icons.palette_outlined,
        'المظهر',
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
            ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
            ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
          ],
          selected: {store.themeMode},
          onSelectionChanged: (s) => store.setThemeMode(s.first),
        ),
      ),
      _group(
        context,
        Icons.language_rounded,
        'اللغة',
        SegmentedButton<AppLang>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: AppLang.ar, label: Text('العربية')),
            ButtonSegment(value: AppLang.en, label: Text('English')),
          ],
          selected: {store.lang},
          onSelectionChanged: (s) => store.setLang(s.first),
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
