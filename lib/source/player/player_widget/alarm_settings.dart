import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart'; // Import main.dart to access flutterLocalNotificationsPlugin
import './ringing_page.dart';
import '../color.dart';

class AlarmSettingsPage extends StatefulWidget {
  const AlarmSettingsPage({super.key});

  @override
  _AlarmSettingsPageState createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  final List<String> _daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];
  final Map<String, TimeOfDay?> _selectedDays = {
    'Senin': null,
    'Selasa': null,
    'Rabu': null,
    'Kamis': null,
    'Jumat': null,
    'Sabtu': null,
    'Minggu': null,
  };

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadSettings();
  }

  void _requestPermissions() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  void _selectDayTime(BuildContext context, String day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedDays[day] ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDays[day] = picked;
      });
    }
  }

  void _saveSettings() async {
    final selectedDaysCount =
        _selectedDays.values.where((time) => time != null).length;
    if (selectedDaysCount < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Pilihan alarm paling sedikit 3 hari dalam 1 minggu')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selectedDays',
      _selectedDays.keys.where((day) => _selectedDays[day] != null).toList(),
    );
    for (var day in _selectedDays.keys) {
      if (_selectedDays[day] != null) {
        await prefs.setInt('${day}_hour', _selectedDays[day]!.hour);
        await prefs.setInt('${day}_minute', _selectedDays[day]!.minute);
      }
    }

    _scheduleAlarms();
    Navigator.pop(context);
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? selectedDays = prefs.getStringList('selectedDays');

    if (selectedDays != null) {
      setState(() {
        for (var day in _daysOfWeek) {
          if (selectedDays.contains(day)) {
            final hour = prefs.getInt('${day}_hour');
            final minute = prefs.getInt('${day}_minute');
            if (hour != null && minute != null) {
              _selectedDays[day] = TimeOfDay(hour: hour, minute: minute);
            }
          }
        }
      });
    }
  }

  void _scheduleAlarms() {
    for (var day in _daysOfWeek) {
      final time = _selectedDays[day];
      if (time != null) {
        final dayOfWeek = _daysOfWeek.indexOf(day) + 1;
        _scheduleAlarm(dayOfWeek, time);
      }
    }
  }

  void _scheduleAlarm(int dayOfWeek, TimeOfDay time) async {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ).add(Duration(days: (dayOfWeek - now.weekday + 7) % 7));

    final alarmSettings = AlarmSettings(
      id: dayOfWeek, // Ensure this is unique for each alarm
      dateTime: scheduledDate,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: const NotificationSettings(
        title: 'Alarm',
        body: 'Saatnya Istirahat!',
        stopButton: 'Stop the alarm',
        icon: '@mipmap/ic_launcher',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    // Call _showNotification when the alarm is scheduled
    _showNotification(dayOfWeek);
  }

  void _showNotification(int alarmId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      alarmId,
      'Alarm',
      'Waktunya Istirahat',
      platformChannelSpecifics,
      payload: alarmId.toString(),
    );

    // Check if the RingingPage is already open
    if (!Navigator.of(context).canPop()) {
      // Navigate to the RingingPage when the notification is tapped
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RingingPage(
            alarmId: alarmId,
            flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
          ),
        ),
      );
    }
  }

  void stopAlarms() async {
    for (var day in _daysOfWeek) {
      if (_selectedDays[day] != null) {
        final dayOfWeek = _daysOfWeek.indexOf(day) + 1;
        await Alarm.stop(dayOfWeek);
        await flutterLocalNotificationsPlugin.cancel(dayOfWeek);
      }
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Alarm',
            style: TextStyle(color: primaryColor, fontSize: 32)),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Pilih Hari:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              Expanded(
                child: ListView(
                  children: _daysOfWeek.map((day) {
                    return Card(
                      color: secondaryColor,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      child: ListTile(
                        title: Text(
                          day,
                          style: const TextStyle(color: primaryColor),
                        ),
                        subtitle: Text(
                          _selectedDays[day] != null
                              ? 'Waktu: ${formatTimeOfDay(_selectedDays[day]!)}'
                              : 'Belum dipilih',
                          style: const TextStyle(color: primaryColor),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.access_time,
                              color: primaryColor),
                          onPressed: () => _selectDayTime(context, day),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: secondaryColor,
                ),
                onPressed: _saveSettings,
                child: const Text('Simpan Pengaturan'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: secondaryColor,
                ),
                onPressed: stopAlarms,
                child: const Text('Stop Alarm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
