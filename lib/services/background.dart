import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/i18n.dart';

/// خدمة أمامية (Foreground Service) تُبقي العملية حيّة والسيرفر شغّالاً
/// حتى بعد إغلاق الشاشة أو الانتقال لتطبيق آخر.
class Background {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'apk_server',
        channelName: tr0('سيرفر التطبيقات'),
        channelDescription: tr0('يُبقي السيرفر الشخصي شغّالاً'),
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(String text) async {
    await FlutterForegroundTask.requestNotificationPermission();
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    if (await FlutterForegroundTask.isRunningService) {
      await update(text);
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: tr0('سيرفري يعمل'),
        notificationText: text,
      );
    }
  }

  static Future<void> update(String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: tr0('سيرفري يعمل'),
        notificationText: text,
      );
    }
  }

  static Future<void> stop() => FlutterForegroundTask.stopService();
}
