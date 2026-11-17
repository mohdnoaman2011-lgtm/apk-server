import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';

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
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const Expanded(
          child: Text('سيرفري', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        ),
        const StatusChip(),
      ]),
      if (store.publicUrl != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: LtrText(store.publicUrl!, style: TextStyle(color: context.cs.primary, fontSize: 13)),
        ),
      if (store.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(store.error!, style: TextStyle(color: context.cs.error)),
        ),
      const SizedBox(height: 20),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Stat('تطبيقات', '${store.apps.length}'),
          const SizedBox(width: 10),
          _Stat('تحميلات', '$downloads'),
          const SizedBox(width: 10),
          _Stat('مساحة', ltr(fmtSize(bytes))),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('تطبيقاتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (store.apps.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text('لم ترفع أي تطبيق بعد', style: TextStyle(color: context.cs.onSurfaceVariant)),
          ),
        ),
      for (final a in store.apps) _AppTile(app: a),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: context.cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});
  final ApkApp app;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailPage(app: app)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              AppIcon(app, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, children: [
                    Text(ltr('v${app.current.versionName} · ${fmtSize(app.current.size)}'),
                        style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13)),
                    Text('${app.downloads} ${tr(context, 'تحميل')}',
                        style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13)),
                  ]),
                ]),
              ),
              IconButton(
                tooltip: tr(context, 'نسخ الرابط'),
                icon: Icon(Icons.copy_rounded, color: context.cs.primary),
                onPressed: () => copyLink(context, store.link(app)),
              ),
            ]),
          ),
        ),
      );
}
