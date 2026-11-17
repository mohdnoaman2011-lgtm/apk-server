import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format.dart';
import '../../models/apk_app.dart';
import '../../state/app_store.dart';
import '../theme.dart';
import '../widgets.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.app});
  final ApkApp app;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (_, __) {
        if (!store.apps.contains(app)) return const Scaffold();
        final link = store.link(app);
        final pub = store.publicLink(app);
        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل التطبيق')),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              AppIcon(app, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  LtrText(app.id, style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13)),
                  Text('${tr(context, 'الإصدار')} ${ltr(app.current.versionName)} · ${ltr(fmtSize(app.current.size))}',
                      style: TextStyle(color: context.cs.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('رابط التحميل (مختصر)', style: TextStyle(color: context.cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('…/${app.token}',
                            style: TextStyle(color: context.cs.tertiary, fontSize: 20, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: tr(context, 'نسخ'),
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => copyLink(context, link),
                    ),
                  ]),
                ]),
              ),
            ),
            if (pub != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الرابط العام (من أي مكان)', style: TextStyle(color: context.cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: SelectableText(pub, style: TextStyle(color: context.cs.primary)),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: tr(context, 'نسخ'),
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () => copyLink(context, pub),
                      ),
                    ]),
                  ]),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: QrImageView(data: pub ?? link, size: 140, backgroundColor: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('رمز QR تلقائي يفتح صفحة التحميل عند المسح (يستخدم الرابط العام إن كان النفق شغّالاً).',
                        style: TextStyle(color: context.cs.onSurfaceVariant)),
                  ),
                ]),
              ),
            ),
            Card(
              child: SwitchListTile(
                title: const Text('تفعيل الرابط'),
                value: app.enabled,
                onChanged: (v) => store.setEnabled(app, v),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.cs.error,
                minimumSize: const Size(0, 52),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف التطبيق وكل إصداراته'),
              onPressed: () async {
                final nav = Navigator.of(context);
                await store.removeApp(app);
                nav.pop();
              },
            ),
          ]),
        );
      },
    );
  }
}
