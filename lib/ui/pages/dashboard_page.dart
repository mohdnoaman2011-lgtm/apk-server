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
    return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 120), children: [
      // ── الترويسة: الشعار والاسم + حالة السيرفر ──
      Row(children: [
        const BrandMark(size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const LtrText('Apk Server',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.3)),
            const SizedBox(height: 2),
            Text('خادم تطبيقاتك الشخصي',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ]),
        ),
        const StatusChip(),
      ]),
      const SizedBox(height: 22),
      const _Hero(),
      const SizedBox(height: 14),
      Row(children: [
        _Stat(Icons.apps_rounded, 'تطبيقات', '${store.apps.length}'),
        const SizedBox(width: 10),
        _Stat(Icons.download_rounded, 'تحميلات', '$downloads'),
        const SizedBox(width: 10),
        _Stat(Icons.storage_rounded, 'مساحة', ltr(fmtSize(bytes))),
      ]),
      const SizedBox(height: 26),
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

/// بطاقة الاتصال: الحالة + الرابط العام + زر الإجراء المناسب.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final IconData icon;
    final String title;
    String sub = '';
    final bool opening = store.tunnelOn && store.tunnelBusy;
    if (!store.running) {
      icon = Icons.power_settings_new_rounded;
      title = 'السيرفر متوقف';
      sub = 'شغّله لبدء استقبال التحميلات';
    } else if (!store.online) {
      icon = Icons.wifi_off_rounded;
      title = 'لا يوجد اتصال';
      sub = 'سيعود تلقائياً عند توفر الشبكة';
    } else if (store.publicUrl != null) {
      icon = Icons.public_rounded;
      title = 'متاح على الإنترنت';
      sub = 'شارك الرابط العام مع أي شخص';
    } else if (opening) {
      icon = Icons.sync_rounded;
      title = 'جارٍ فتح النفق…';
    } else if (store.tunnelOn && store.tunnelError != null) {
      icon = Icons.error_outline_rounded;
      title = 'تعذّر فتح النفق';
      sub = store.tunnelError!;
    } else {
      icon = Icons.wifi_tethering_rounded;
      title = 'يعمل على الشبكة المحلية';
      sub = 'فعّل النفق للوصول من الإنترنت';
    }

    final Widget? action;
    if (!store.running) {
      action = FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => store.setServer(true),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('تشغيل السيرفر'),
      );
    } else if (store.publicUrl != null) {
      action = Row(children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => copyLink(context, store.publicUrl!),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('نسخ الرابط العام'),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => store.setTunnel(false),
          icon: const Icon(Icons.stop_rounded, size: 18),
          label: const Text('إيقاف النفق'),
        ),
      ]);
    } else if (opening) {
      action = Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(minHeight: 4),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => store.setTunnel(false), child: const Text('إلغاء')),
      ]);
    } else if (store.tunnelOn && store.tunnelError != null) {
      action = Row(children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: store.retryTunnel,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('إعادة المحاولة'),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => store.setTunnel(false),
          child: const Text('إلغاء'),
        ),
      ]);
    } else if (store.online) {
      action = FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => store.setTunnel(true),
        icon: const Icon(Icons.public_rounded, size: 20),
        label: const Text('تفعيل الوصول من الإنترنت'),
      );
    } else {
      action = null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: heroDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ]),
          ),
        ]),
        if (store.publicUrl != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(Icons.link_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: LtrText(store.publicUrl!,
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ]),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action],
        if (store.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
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
        child: SizedBox(
          height: 112,
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconBadge(icon, size: 32),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                Text(label, style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 12)),
              ]),
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
          Text('اضغط على زر الرفع للبدء', style: TextStyle(color: context.cs.onSurfaceVariant)),
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
                const SizedBox(height: 5),
                Row(children: [
                  Flexible(
                    child: Text(ltr('v${app.current.versionName} · ${fmtSize(app.current.size)}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.download_rounded, size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text('${app.downloads}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: tr(context, 'نسخ الرابط'),
              icon: Icon(Icons.copy_rounded, size: 20, color: cs.primary),
              style: IconButton.styleFrom(backgroundColor: cs.primary.withValues(alpha: .12)),
              onPressed: () => copyLink(context, store.link(app)),
            ),
          ]),
        ),
      ),
    );
  }
}
