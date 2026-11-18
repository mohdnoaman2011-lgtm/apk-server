import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'state/app_store.dart';
import 'ui/i18n.dart' show AppLang, LangScope;
import 'ui/pages/shell.dart';
import 'ui/splash_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ApkServerApp());
}

class ApkServerApp extends StatelessWidget {
  const ApkServerApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (_, __) {
          final lang = store.lang;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Apk Server',
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: store.themeMode,
            builder: (c, child) => LangScope(
              lang: lang,
              child: Directionality(
                textDirection: lang == AppLang.ar ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              ),
            ),
            home: const Bootstrap(),
          );
        },
      );
}

/// يعرض شاشة البداية أثناء تهيئة البيانات وتشغيل الخدمة (بحد أدنى ~1.8 ثانية).
class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late final Future<void> _ready = _boot();

  Future<void> _boot() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1800));
    try {
      await store.init();
    } catch (e) {
      debugPrint('init failed: $e');
    }
    await minDelay;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _ready,
        builder: (_, snap) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: snap.connectionState == ConnectionState.done
              ? const WithForegroundTask(key: ValueKey('app'), child: Shell())
              : const SplashPage(key: ValueKey('splash')),
        ),
      );
}
