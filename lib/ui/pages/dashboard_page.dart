import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/apk_app.dart';
import '../../state/app_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = store.apps.fold<int>(0, (s, a) => s + a.downloads);
    final bytes = store.apps.fold<int>(0, (s, a) => s + a.versions.fold(0, (x, v) => x + v.size));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 96), children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('سيرفري', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            LtrText('${store.ip}:${AppStore.port}', style: const TextStyle(color: kMuted)),
            if (store.publicUrl != null)
              LtrText(store.publicUrl!, style: const TextStyle(color: kGreen, fontSize: 13)),
          ]),
        ),
        const StatusChip(),
      ]),
      if (store.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(store.error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      const SizedBox(height: 16),
      Row(children: [
        _stat('تطبيقات', '${store.apps.length}'),
        _stat('تحميلات', '$downloads'),
        _stat('مساحة', fmtSize(bytes)),
      ]),
      const SizedBox(height: 8),
      const Text('تطبيقاتي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (store.apps.isEmpty)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('لم ترفع أي تطبيق بعد', style: TextStyle(color: kMuted))),
        ),
      for (final a in store.apps) _AppTile(app: a),
    ]);
  }

  Widget _stat(String k, String v) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text(k, style: const TextStyle(color: kMuted)),
            ]),
          ),
        ),
      );
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});
  final ApkApp app;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: AppIcon(app),
          title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              'v${app.current.versionName} · ${fmtSize(app.current.size)} · ${app.downloads} تحميل'),
          trailing: IconButton(
            tooltip: 'نسخ الرابط',
            icon: const Icon(Icons.copy_rounded, color: kGreen),
            onPressed: () => copyLink(context, store.link(app)),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailPage(app: app)),
          ),
        ),
      );
}
