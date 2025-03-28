import 'package:flutter/material.dart';
import 'source/material_app.dart'; // Assuming this is your main app widget
import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission handler
import 'source/admin_page.dart'; // Import the admin page

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();

  // Initialize notification settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Create a notification channel for alarms
  const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    'alarm_channel', // Same as the channel ID in _showNotification
    'Alarm Notifications',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('alarm_sound'),
  );

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // Initialize the plugin with a callback for handling notification actions
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle notification actions here
      if (response.payload == 'stop_alarm') {
        // Stop all alarms when the "Stop Alarm" action is tapped
        await _stopAllAlarms();
      }
    },
  );

  // Create the notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alarmChannel);

  // Request notification permissions
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Load user preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userid');

  runApp(MainApp(userId: userId));
}

// Function to stop all alarms
Future<void> _stopAllAlarms() async {
  // Stop all alarms (you can customize this logic based on your app's requirements)
  await Alarm.stopAll();
  await flutterLocalNotificationsPlugin.cancelAll();
}

class MainApp extends StatelessWidget {
  final String? userId;

  const MainApp({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: userId != null ? const TibraApp() : const AdminPage(),
    );
  }
}
