import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';

import '../../core/format.dart';
import '../../state/app_store.dart';
import '../theme.dart';
import '../widgets.dart';

class VersionsPage extends StatelessWidget {
  const VersionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 96), children: [
      const Text('سجل الإصدارات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (store.apps.isEmpty)
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text('لا توجد إصدارات بعد', style: TextStyle(color: context.cs.onSurfaceVariant)),
          ),
        ),
      for (final a in store.apps) ...[
        Row(children: [
          AppIcon(a, size: 32),
          const SizedBox(width: 10),
          Text(a.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        for (var i = 0; i < a.versions.length; i++)
          Card(
            child: ListTile(
              title: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LtrText('v${a.versions[i].versionName}'),
              ),
              subtitle: Text(
                '${ltr(fmtDate(a.versions[i].date))} · ${ltr(fmtSize(a.versions[i].size))}'
                '${a.versions[i].notes.isEmpty ? '' : '\n${a.versions[i].notes}'}',
              ),
              isThreeLine: a.versions[i].notes.isNotEmpty,
              trailing: i == 0
                  ? const Chip(label: Text('الحالية'))
                  : IconButton(
                      tooltip: tr(context, 'حذف هذا الإصدار'),
                      icon: Icon(Icons.delete_outline, color: context.cs.error),
                      onPressed: () => store.removeVersion(a, a.versions[i]),
                    ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    ]);
  }
}
