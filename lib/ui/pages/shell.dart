import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';

import '../../state/app_store.dart';
import '../upload.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';
import 'versions_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [DashboardPage(), VersionsPage(), SettingsPage()];
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (_, __) => Column(children: [
            if (store.picking) const LinearProgressIndicator(minHeight: 3),
            Expanded(child: pages[tab]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => uploadApk(context),
        icon: const Icon(Icons.upload_rounded),
        label: const Text('رفع ملف APK'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: tr(context, 'الرئيسية')),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: tr(context, 'السجل')),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: tr(context, 'الإعدادات')),
        ],
      ),
    );
  }
}
