import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'WebDAV X',
      initialNotificationContent: '准备下载...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('update').listen((event) async {
    if (event != null) {
      final filenames = event['filenames'] as List<dynamic>?;

      if (filenames != null && filenames.isNotEmpty) {
        final displayList = filenames.cast<String>();
        final count = displayList.length;

        // Cancel all previous individual notifications
        for (int i = 0; i < 100; i++) {
          await flutterLocalNotificationsPlugin.cancel(1000 + i);
        }

        // Create individual notification for each file
        for (int i = 0; i < displayList.length; i++) {
          await flutterLocalNotificationsPlugin.show(
            1000 + i,
            '下载/解密中',
            displayList[i],
            NotificationDetails(
              android: AndroidNotificationDetails(
                'my_foreground',
                'MY FOREGROUND SERVICE',
                icon: 'ic_launcher',
                ongoing: true,
                groupKey: 'webdav_downloads',
                setAsGroupSummary: false,
              ),
            ),
          );
        }

        // Create summary notification
        await flutterLocalNotificationsPlugin.show(
          888,
          'WebDAV X',
          '正在处理 $count 个文件',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_launcher',
              ongoing: true,
              groupKey: 'webdav_downloads',
              setAsGroupSummary: true,
              styleInformation: InboxStyleInformation(
                displayList,
                contentTitle: '正在处理 $count 个文件',
                summaryText: '点击展开查看详情',
              ),
            ),
          ),
        );
      }
    }
  });
}
