import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class Reminder {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
    _ready = true;
  }

  // يجدول تذكيراً في الساعة 9 مساءً لكل يوم من الأيام الأربعة عشر القادمة.
  // إذا قرأت اليوم فلا يُجدول تذكير اليوم.
  static Future<void> schedule({required bool readToday}) async {
    try {
      await init();
      await _plugin.cancelAll();
      final now = DateTime.now();
      for (var i = 0; i < 14; i++) {
        if (i == 0 && readToday) continue;
        final when = DateTime(now.year, now.month, now.day + i, 21, 0);
        if (!when.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          i,
          'لا تُضيّع الاستريك',
          'اقرأ اليوم من القرآن الكريم قبل أن ينتهي اليوم',
          tz.TZDateTime.from(when, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'streak_reminder',
              'تذكير الاستريك',
              channelDescription: 'تذكير يومي بالقراءة',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {
      // لا نوقف التطبيق إذا فشلت الإشعارات
    }
  }
}
