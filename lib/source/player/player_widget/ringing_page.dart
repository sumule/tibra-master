import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart'; // Import the Alarm package
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import notifications
import '../color.dart'; // Import your color constants

class RingingPage extends StatelessWidget {
  final int alarmId;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const RingingPage({
    Key? key,
    required this.alarmId,
    required this.flutterLocalNotificationsPlugin,
  }) : super(key: key);

  void _stopAlarm(BuildContext context) async {
    print('Stopping alarm with ID: $alarmId');

    // Stop the alarm using the Alarm package
    await Alarm.stop(alarmId);
    print('Alarm with ID $alarmId stopped.');

    // Stop all alarms for all days
    final List<String> daysOfWeek = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    for (var day in daysOfWeek) {
      final dayOfWeek = daysOfWeek.indexOf(day) + 1;
      await Alarm.stop(dayOfWeek);
      await flutterLocalNotificationsPlugin.cancel(dayOfWeek);
    }

    // Dismiss all notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    // Close the RingingPage
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alarm Berbunyi',
          style: TextStyle(color: primaryColor, fontSize: 32),
        ),
        backgroundColor: secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [secondaryColor, accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: gradientstop,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Alarm Berbunyi!',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                ),
                onPressed: () => _stopAlarm(context),
                child: const Text(
                  'Matikan Alarm',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
