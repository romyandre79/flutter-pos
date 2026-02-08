import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_pos_offline/data/models/order.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleOrderReminder(Order order) async {
    if (order.dueDate == null || order.id == null) return;

    final dueDate = order.dueDate!;
    final now = DateTime.now();

    // Schedule for 2 days before
    final reminder2Days = dueDate.subtract(const Duration(days: 2));
    if (reminder2Days.isAfter(now)) {
      await _scheduleNotification(
        id: order.id! * 10 + 2, // Unique ID for 2-day reminder
        title: 'Reminder: Order #${order.invoiceNo}',
        body: 'Order for ${order.customerName} is due in 2 days.',
        scheduledDate: reminder2Days,
      );
    }

    // Schedule for 1 day before
    final reminder1Day = dueDate.subtract(const Duration(days: 1));
    if (reminder1Day.isAfter(now)) {
      await _scheduleNotification(
        id: order.id! * 10 + 1, // Unique ID for 1-day reminder
        title: 'Urgent: Order #${order.invoiceNo}',
        body: 'Order for ${order.customerName} is due tomorrow!',
        scheduledDate: reminder1Day,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'order_reminders',
          'Order Reminders',
          channelDescription: 'Notifications for upcoming order due dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelOrderReminders(int orderId) async {
    await flutterLocalNotificationsPlugin.cancel(orderId * 10 + 2);
    await flutterLocalNotificationsPlugin.cancel(orderId * 10 + 1);
  }
}
