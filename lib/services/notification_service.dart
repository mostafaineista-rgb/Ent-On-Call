import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'repository.dart';
import 'notification_history_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      debugPrint('Initializing Timezones...');
      tz.initializeTimeZones();
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      // In version 5.0.2+, getLocalTimezone returns a TimezoneInfo object
      final String locationName = timeZoneInfo is String ? timeZoneInfo : (timeZoneInfo as dynamic).name;
      debugPrint('Local Timezone: $locationName');
      
      try {
        tz.setLocalLocation(tz.getLocation(locationName));
      } catch (e) {
        debugPrint('Failed to get location $locationName, falling back to UTC. Error: $e');
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      debugPrint('General timezone initialization error, falling back to UTC. Error: $e');
      tz.setLocalLocation(tz.UTC);
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Log to history when notification is tapped
          if (response.payload != null) {
            // we could parse payload here
          }
        },
      );

      // Request permissions for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Failed to initialize local notifications plugin. Error: $e');
    }
  }

  static Future<void> scheduleDutyReminders(
      AuthService authService, Repository repository) async {
    if (kIsWeb) return;

    final user = await authService.getLoggedInUser();
    if (user == null) {
      await _notificationsPlugin.cancelAll();
      return;
    }

    final duties = await repository.getDuties();
    // Instead of cancelAll(), we could cancel only specific IDs if needed, 
    // but for now, we'll keep it simple and just ensure we don't clear delivered ones 
    // by using a more targeted approach if possible, or just removing this blanket call.
    // However, pending notifications need to be updated. 
    // cancelAll() removes BOTH pending and delivered.
    // To only remove pending, we should use specific IDs or just accept some overlap.
    // Let's remove cancelAll() and rely on ID overwriting.

    final now = DateTime.now();
    int notificationId = 100; // Starting ID for duty reminders

    for (var duty in duties) {
      if (duty.residentIds.contains(user.id)) {
        try {
          // duty.date is expected in YYYY-MM-DD
          DateTime dutyDate = DateTime.parse(duty.date);
          
          // Remind at 9:00 PM (21:00) on the day before the duty
          DateTime triggerTime = dutyDate.subtract(const Duration(days: 1)).copyWith(
                hour: 21,
                minute: 0,
                second: 0,
                millisecond: 0,
                microsecond: 0,
              );

          if (triggerTime.isAfter(now)) {
            await _notificationsPlugin.zonedSchedule(
              id: notificationId++,
              title: 'Tomorrow On-Call Reminder',
              body: 'You are on call tomorrow. Wishing you a trouble-free shift in the hospital. اتمنى لك خفارة سعيدة',
              scheduledDate: tz.TZDateTime.from(triggerTime, tz.local),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'duty_reminders_channel',
                  'Duty Reminders',
                  channelDescription: 'Reminders for upcoming on-call duties',
                  importance: Importance.max,
                  priority: Priority.high,
                  showWhen: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          }
        } catch (e) {
          debugPrint('Error scheduling notification for duty ${duty.date}: $e');
        }
      }
    }
    
    debugPrint('Scheduled ${notificationId - 100} duty reminders.');
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb) return;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _notificationsPlugin.show(
      id: 999,
      title: 'Notification Test | تجربة الإشعارات',
      body: 'You are on call tomorrow. Wishing you a trouble-free shift in the hospital. اتمنى لك خفارة سعيدة',
      notificationDetails: platformChannelSpecifics,
    );

    // Save to history
    await NotificationHistoryService.addMessage(
      'Notification Test | تجربة الإشعارات',
      'You are on call tomorrow. Wishing you a trouble-free shift in the hospital. اتمنى لك خفارة سعيدة',
    );
  }
}
