import 'package:flutter/material.dart' hide Text;

import '../../core/format.dart';
import '../../models/apk_app.dart';
import '../../state/app_store.dart';
import '../brand.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final downloads = store.apps.fold<int>(0, (s, a) => s + a.downloads);
    final bytes = store.apps.fold<int>(0, (s, a) => s + a.versions.fold(0, (x, v) => x + v.size));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 120), children: [
      Row(children: [
        const BrandMark(size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const LtrText('Apk Server',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.3)),
            Text('خادم تطبيقاتك الشخصي',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ]),
        ),
      ]),
      const SizedBox(height: 20),
      const _Hero(),
      const SizedBox(height: 16),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Stat(Icons.apps_rounded, 'تطبيقات', '${store.apps.length}'),
          const SizedBox(width: 10),
          _Stat(Icons.download_rounded, 'تحميلات', '$downloads'),
          const SizedBox(width: 10),
          _Stat(Icons.storage_rounded, 'مساحة', ltr(fmtSize(bytes))),
        ]),
      ),
      const SizedBox(height: 22),
      Row(children: [
        const Text('تطبيقاتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('${store.apps.length}',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
      const SizedBox(height: 12),
      if (store.apps.isEmpty) const _Empty(),
      for (final a in store.apps) _AppTile(app: a),
    ]);
  }
}

/// بطاقة الحالة الرئيسية.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final String title;
    String sub = '';
    if (!store.running) {
      title = 'السيرفر متوقف';
      sub = 'شغّله من الإعدادات';
    } else if (!store.online) {
      title = 'لا يوجد اتصال';
      sub = 'سيعود تلقائياً عند توفر الشبكة';
    } else if (store.publicUrl != null) {
      title = 'الرابط العام';
    } else {
      title = 'يعمل على الشبكة المحلية';
      sub = 'فعّل النفق للوصول من الإنترنت';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: heroDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const StatusChip(),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        if (store.publicUrl != null)
          Row(children: [
            Expanded(
              child: LtrText(store.publicUrl!,
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: tr(context, 'نسخ الرابط'),
              icon: Icon(Icons.copy_rounded, color: cs.primary),
              onPressed: () => copyLink(context, store.publicUrl!),
            ),
          ])
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(sub, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        if (store.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(store.error!, style: TextStyle(color: cs.error)),
          ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBadge(icon, size: 34),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(children: [
          const IconBadge(Icons.cloud_upload_outlined, size: 72),
          const SizedBox(height: 16),
          const Text('لم ترفع أي تطبيق بعد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('اضغط "رفع ملف APK" للبدء', style: TextStyle(color: context.cs.onSurfaceVariant)),
        ]),
      );
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});
  final ApkApp app;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailPage(app: app)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            AppIcon(app, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  if (!app.enabled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('معطّل', style: TextStyle(color: cs.secondary, fontSize: 11)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Wrap(spacing: 8, children: [
                  Text(ltr('v${app.current.versionName} · ${fmtSize(app.current.size)}'),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  Text('${app.downloads} ${tr(context, 'تحميل')}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ]),
              ]),
            ),
            IconButton(
              tooltip: tr(context, 'نسخ الرابط'),
              icon: Icon(Icons.copy_rounded, color: cs.primary),
              onPressed: () => copyLink(context, store.link(app)),
            ),
          ]),
        ),
      ),
    );
  }
}
