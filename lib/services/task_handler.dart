import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'server_runtime.dart';

/// نقطة دخول عزل الخدمة (تُستدعى من النظام ولو كانت الواجهة مغلقة).
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ServerTaskHandler());
}

class ServerTaskHandler extends TaskHandler {
  final _rt = ServerRuntime();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) =>
      _rt.init(FlutterForegroundTask.sendDataToMain);

  @override
  void onRepeatEvent(DateTime timestamp) => unawaited(_rt.tick());

  @override
  void onReceiveData(Object data) {
    if (data is Map) unawaited(_rt.handle(data));
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') unawaited(_rt.requestStop());
  }

  @override
  Future<void> onDestroy(DateTime timestamp) => _rt.dispose();
}
