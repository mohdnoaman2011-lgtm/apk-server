import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'state/app_store.dart';
import 'ui/i18n.dart' show AppLang, LangScope;
import 'ui/pages/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await store.init();
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
            // WithForegroundTask: زر الرجوع يُصغّر التطبيق بدل إغلاقه فيبقى السيرفر شغّالاً
            home: const WithForegroundTask(child: Shell()),
          );
        },
      );
}
