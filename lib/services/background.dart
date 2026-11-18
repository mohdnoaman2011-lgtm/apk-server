import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/i18n.dart';
import 'task_handler.dart';

/// تشغيل خدمة الخلفية (Foreground Service). السيرفر نفسه يعمل داخلها
/// (انظر server_runtime.dart) فيستمر بعد إغلاق التطبيق.
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
        eventAction: ForegroundTaskEventAction.repeat(15000), // فحص دوري كل 15 ثانية
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    await FlutterForegroundTask.requestNotificationPermission();
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: tr0('سيرفري يعمل'),
      notificationText: tr0('جارٍ التشغيل…'),
      notificationButtons: [NotificationButton(id: 'stop', text: tr0('إيقاف'))],
      callback: startCallback,
    );
  }

  static Future<void> stop() => FlutterForegroundTask.stopService();
}
