import 'package:flutter/material.dart';
import 'player_widget/audio_player_controller.dart';
import 'player_widget/play_pause_button.dart';
import 'player_widget/stop_button.dart';
// import 'player_widget/choose_button.dart';

import 'player_widget/alarm_button.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'player_widget/alarm_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<Player> {
  late AudioPlayerController _controller;
  String? _userId;
  late mongo.Db db;
  int _tapCount = 0;
  bool _isFinishedPageOpen = false;

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    setState(() {
      _userId = userId;
    });
  }

  Future<void> _shareCsv() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/history.csv';
      final file = File(filePath);

      if (await file.exists()) {
        await Share.shareXFiles([XFile('${directory.path}/history.csv')],
            text: 'Here is the history CSV file.');
      } else {
        print('CSV file does not exist.');
      }
    } catch (e) {
      print('Error sharing CSV: $e');
    }
  }

  @override
  void dispose() {
    _controller.disposePlayer();
    super.dispose();
  }

  // void _onAudioSelected(String audioPath) {
  //   setState(() {
  //     // _selectedAudio = audioPath;
  //   });
  //   _controller.loadAudio(audioPath);
  // }

  // void _navigateToAlarmSettings() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const AlarmSettingsPage(),
  //     ),
  //   );
  // }

  void navigateToAlarmSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlarmSettingsPage()),
    );
  }

  void _onAudioComplete() {
    print('Audio has finished playing in Player widget');
    if (!_isFinishedPageOpen) {
      _isFinishedPageOpen = true; // Set the flag to true
      _controller.onAudioComplete2(context).then((_) {
        _isFinishedPageOpen = false; // Reset the flag when navigation completes
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AudioPlayerController(onAudioComplete: _onAudioComplete);
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayPauseButton(controller: _controller),
        StopButton(controller: _controller),
        const AlarmButton(),
        if (_userId != null)
          GestureDetector(
            onTap: () {
              _tapCount++;
              if (_tapCount == 10) {
                _shareCsv();
                _tapCount = 0; // Reset tap count
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "ID: " + _userId!,
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
