import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'state/app_store.dart';
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
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        // WithForegroundTask: زر الرجوع يُصغّر التطبيق بدل إغلاقه فيبقى السيرفر شغّالاً
        home: const WithForegroundTask(child: Shell()),
      );
}
