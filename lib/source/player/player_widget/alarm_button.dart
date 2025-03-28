import 'package:flutter/material.dart';
import 'alarm_settings.dart';
import '../color.dart';

class AlarmButton extends StatelessWidget {
  const AlarmButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.alarm),
      iconSize: 96,
      color: primaryColor,
      onPressed: () {
        _navigateToAlarmSettings(context);
      },
    );
  }

  void _navigateToAlarmSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlarmSettingsPage()),
    );
  }
}
