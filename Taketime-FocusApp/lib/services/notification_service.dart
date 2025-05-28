import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:rxdart/rxdart.dart'; // For handling notification taps

// Helper class to handle notification taps globally
final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    print('[NotificationService] Time zones initialized.');

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print(
          '[NotificationService] Notification clicked: ${response.payload}',
        );
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationResponseBackground,
    );

    // Request permissions and check exact alarm capability
    final androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Request POST_NOTIFICATIONS permission for Android 13+
      try {
        final bool? postNotificationsGranted =
            await androidImplementation.requestNotificationsPermission();
        if (postNotificationsGranted != true) {
          print(
            '[NotificationService] POST_NOTIFICATIONS permission not granted.',
          );
        } else {
          print('[NotificationService] POST_NOTIFICATIONS permission granted.');
        }
      } catch (e) {
        print(
          '[NotificationService] Error requesting POST_NOTIFICATIONS permission: $e',
        );
      }

      // On Android 12+, scheduling exact alarms requires SCHEDULE_EXACT_ALARM permission.
      // We've added it to AndroidManifest.xml. The system might prompt the user.
      // The plugin will throw PlatformException if permission is denied.
      // We will catch this exception during scheduling and guide the user.
    } else {
      print(
        '[NotificationService] Android implementation not found or not applicable for permission checks.',
      );
    }

    _configureLocalTimeZone();
  }

  @pragma('vm:entry-point')
  static void notificationResponseBackground(
    NotificationResponse notificationResponse,
  ) {
    // Handle background notification taps here
    print(
      'Background notification tapped with payload: ${notificationResponse.payload}',
    );
    selectNotificationSubject.add(notificationResponse.payload);
    // Note: This function runs in its own isolate, so you can't directly update UI.
    // You might use platform channels or other mechanisms to communicate with the main isolate.
  }

  Future<void> _configureLocalTimeZone() async {
    // For this to work, you need to initialize timezones first
    // tzdata.initializeUfc(); is called in init()
    tz.setLocalLocation(
      tz.getLocation('Asia/Ho_Chi_Minh'),
    ); // Set your local time zone
    // Or you might try to determine the system timezone dynamically
    // final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    // tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    print(
      '[NotificationService] Scheduling notification ID: $id at $scheduledTime',
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'plan_notifications',
            'Plan Notifications',
            channelDescription: 'Notifications for upcoming plans',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print(
        '[NotificationService] Successfully scheduled notification ID: $id',
      );
    } catch (e) {
      print('[NotificationService] Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    print(
      '[NotificationService] Attempting to cancel notification with ID: $id',
    );
    await _notifications.cancel(id);
    print('[NotificationService] Cancelled notification with ID: $id');
  }

  Future<void> cancelAllNotifications() async {
    print('[NotificationService] Cancelling all notifications');
    await _notifications.cancelAll();
    print('[NotificationService] All notifications cancelled.');
  }

  // Generate a unique integer ID for each notification
  // This combines the task ID (String) and the notification type (int)
  // Type codes: 0 for 30min_start, 1 for timestart, 2 for 10min_end
  int generateNotificationId(String taskId, int typeCode) {
    // Sử dụng hashCode tuyệt đối để đảm bảo giá trị dương.
    // Kết hợp giá trị băm đã xử lý với typeCode để tạo ID duy nhất cho mỗi loại thông báo.
    // Đảm bảo kết quả nằm trong phạm vi số nguyên 32-bit.

    // Lấy giá trị tuyệt đối của hashCode
    final int absHashCode = taskId.hashCode.abs();

    // Kết hợp absHashCode với typeCode. Chúng ta có thể sử dụng phép toán đơn giản
    // như nhân với một hệ số nhỏ (ví dụ: 10) và cộng typeCode.
    // Tuy nhiên, để đảm bảo không tràn số 32-bit, chúng ta cần giới hạn absHashCode.
    // Giá trị tối đa của int32 là 2147483647.
    // Chúng ta có thể giới hạn absHashCode để khi nhân với 10 và cộng 2 vẫn không vượt quá giá trị này.
    // 2147483647 / 10 = 214748364.7. Giới hạn absHashCode dưới 214748364.
    final int limitedHashCode = absHashCode % 214748364;

    // Kết hợp giới hạn hash code và typeCode
    return limitedHashCode * 10 + typeCode;
  }
}
