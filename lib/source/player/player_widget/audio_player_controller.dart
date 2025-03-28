import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import '../audio_selection.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import './finished_page.dart';

class AudioPlayerController extends ValueNotifier<bool>
    with WidgetsBindingObserver {
  late AudioPlayer _audioPlayerMaster;
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volumeMaster = 0.5;
  String? _userId;
  late mongo.Db db;
  VoidCallback? onAudioComplete;
  bool _audioCompleted =
      false; // Flag to ensure _onAudioComplete is called only once

  AudioPlayerController({this.onAudioComplete}) : super(false) {
    WidgetsBinding.instance.addObserver(this);
    _audioPlayerMaster = AudioPlayer();
    _audioPlayerMaster
        .setLoopMode(LoopMode.off); // Set initial loop mode to off
    _loadVolume(); // Load volume from SharedPreferences
    _setAudioMain();
    _connectToMongoDB(); // Connect to MongoDB
    _audioPlayerMaster.durationStream.listen((Duration? d) {
      if (d != null) {
        _duration = d;
        notifyListeners();
      }
    });

    _audioPlayerMaster.positionStream.listen((Duration p) {
      _position = p;
      notifyListeners();
    });

    // _audioPlayerMaster.playerStateStream.listen((PlayerState state) {
    //   if (state.processingState == ProcessingState.completed &&
    //       !_audioCompleted) {
    //     _audioCompleted = true;
    //     _onAudioComplete(context);
    //   } else if (state.processingState != ProcessingState.completed) {
    //     _audioCompleted = false; // Reset flag for future plays
    //   }
    // });

    _audioPlayerMaster.playerStateStream.listen((PlayerState state) {
      if (state.processingState == ProcessingState.completed &&
          !_audioCompleted) {
        _audioCompleted = true; // Set the flag to prevent multiple triggers
        if (onAudioComplete != null) {
          onAudioComplete!(); // Trigger the callback
        }
      } else if (state.processingState != ProcessingState.completed) {
        _audioCompleted = false; // Reset the flag for future plays
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureDbConnection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayerMaster.dispose();
    super.dispose();
  }

  Future<void> _connectToMongoDB() async {
    List<String> uris = [
      "mongodb://sumule:Polaris%2A182@cluster0-shard-00-00.fec7h.mongodb.net/?tls=true&readPreference=secondary",
      "mongodb://sumule:Polaris%2A182@cluster0-shard-00-01.fec7h.mongodb.net/?tls=true&readPreference=secondary",
      "mongodb://sumule:Polaris%2A182@cluster0-shard-00-02.fec7h.mongodb.net/?tls=true&readPreference=secondary"
    ];

    for (String uri in uris) {
      try {
        db = mongo.Db(uri);
        await db.open();
        print('Connected to $uri');
        break;
      } catch (e) {
        print('Failed to connect to $uri: $e');
      }
    }
  }

  Future<void> _ensureDbConnection() async {
    if (db.state != mongo.State.OPEN) {
      await _connectToMongoDB();
    }
  }

  // Future<void> saveToCsv(Map<String, dynamic> data) async {
  //   try {
  //     final directory = await getApplicationDocumentsDirectory();
  //     final filePath = '${directory.path}/history.csv';
  //     final file = File(filePath);

  //     List<List<dynamic>> csvData = [
  //       [
  //         'userid',
  //         'play',
  //         'pause',
  //         'stop',
  //         'week',
  //         'date',
  //         'time'
  //       ], // Header row
  //     ];

  //     if (await file.exists()) {
  //       // Read existing data
  //       final existingData = await file.readAsString();
  //       csvData.addAll(const CsvToListConverter().convert(existingData));
  //     }

  //     // Add new data
  //     csvData.add([
  //       data['userid'],
  //       data['play'],
  //       data['pause'],
  //       data['stop'],
  //       data['week'],
  //       data['date'],
  //       data['time'],
  //     ]);

  //     // Write to CSV
  //     final csvString = const ListToCsvConverter().convert(csvData);
  //     await file.writeAsString(csvString);

  //     print('Data saved to CSV: $filePath');
  //   } catch (e) {
  //     print('Error saving to CSV: $e');
  //   }
  // }
  Future<void> saveToCsv(Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/history.csv';
      final file = File(filePath);

      List<List<dynamic>> csvData = [];

      if (await file.exists()) {
        // Read existing data
        final existingData = await file.readAsString();
        final existingCsv = const CsvToListConverter().convert(existingData);

        // Check if the header already exists
        if (existingCsv.isNotEmpty &&
            existingCsv[0].contains('userid') &&
            existingCsv[0].contains('play') &&
            existingCsv[0].contains('pause') &&
            existingCsv[0].contains('stop') &&
            existingCsv[0].contains('week') &&
            existingCsv[0].contains('date') &&
            existingCsv[0].contains('time')) {
          csvData.addAll(
              existingCsv); // Add existing data without rewriting the header
        } else {
          // Add header if it doesn't exist
          csvData.add([
            'userid',
            'play',
            'pause',
            'stop',
            'week',
            'date',
            'time',
          ]);
          csvData.addAll(existingCsv); // Add existing data
        }
      } else {
        // Add header if the file doesn't exist
        csvData.add([
          'userid',
          'play',
          'pause',
          'stop',
          'week',
          'date',
          'time',
        ]);
      }

      // Add new data
      csvData.add([
        data['userid'],
        data['play'],
        data['pause'],
        data['stop'],
        data['week'],
        data['date'],
        data['time'],
      ]);

      // Write to CSV
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      print('Data saved to CSV: $filePath');
    } catch (e) {
      print('Error saving to CSV: $e');
    }
  }

  Future<void> _saveOrUpdateCsv(Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/history.csv';
      final file = File(filePath);

      List<List<dynamic>> csvData = [];
      bool updated = false;

      if (await file.exists()) {
        // Read existing data
        final existingData = await file.readAsString();
        final existingCsv = const CsvToListConverter().convert(existingData);

        // Check if the header already exists
        if (existingCsv.isNotEmpty &&
            existingCsv[0].contains('userid') &&
            existingCsv[0].contains('play') &&
            existingCsv[0].contains('pause') &&
            existingCsv[0].contains('stop') &&
            existingCsv[0].contains('week') &&
            existingCsv[0].contains('date') &&
            existingCsv[0].contains('time')) {
          csvData.addAll(
              existingCsv); // Add existing data without rewriting the header
        } else {
          // Add header if it doesn't exist
          csvData.add([
            'userid',
            'play',
            'pause',
            'stop',
            'week',
            'date',
            'time',
          ]);
          csvData.addAll(existingCsv); // Add existing data
        }

        // Check if an entry for the specific date already exists
        for (int i = 1; i < csvData.length; i++) {
          if (csvData[i][5] == data['date']) {
            // Compare the 'date' column
            if (data['week'] != null) {
              // Check if weekNumber is not null
              csvData[i][6] = data['time']; // Update only the 'time' column
            } else {
              // Update the entire row if weekNumber is null
              csvData[i] = [
                data['userid'],
                data['play'],
                data['pause'],
                data['stop'],
                data['week'],
                data['date'],
                data['time'],
              ];
            }
            updated = true;
            break;
          }
        }
      } else {
        // Add header if the file doesn't exist
        csvData.add([
          'userid',
          'play',
          'pause',
          'stop',
          'week',
          'date',
          'time',
        ]);
      }

      // If no entry was updated, add a new row
      if (!updated) {
        csvData.add([
          data['userid'],
          data['play'],
          data['pause'],
          data['stop'],
          data['week'],
          data['date'],
          data['time'],
        ]);
      }

      // Write updated data to the CSV file
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      print('Data saved to CSV: $filePath');
    } catch (e) {
      print('Error saving to CSV: $e');
    }
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    _userId = userId;
  }

  Future<void> _insertMongoStart() async {
    await _loadPreferences();
    await _ensureDbConnection();
    var collection = db.collection('history');
    await collection.insertOne({
      'userid': _userId,
      'play': 'play',
      'pause': '',
      'stop': '',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': DateTime.now().toIso8601String().split('T')[1],
    });
    var currentDate = DateTime.now().toIso8601String().split('T')[0];
    var currentTime = DateTime.now().toIso8601String().split('T')[1];
    await saveToCsv({
      'userid': _userId,
      'play': 'play',
      'pause': '',
      'stop': '',
      'week': '',
      'date': currentDate,
      'time': currentTime,
    });
  }

  Future<void> _insertMongoPause() async {
    await _loadPreferences();
    await _ensureDbConnection();
    var collection = db.collection('history');
    await collection.insertOne({
      'userid': _userId,
      'play': '',
      'pause': 'pause',
      'stop': '',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': DateTime.now().toIso8601String().split('T')[1],
    });
    var currentDate = DateTime.now().toIso8601String().split('T')[0];
    var currentTime = DateTime.now().toIso8601String().split('T')[1];
    await saveToCsv({
      'userid': _userId,
      'play': '',
      'pause': 'pause',
      'stop': '',
      'week': '',
      'date': currentDate,
      'time': currentTime,
    });
  }

  Future<void> _insertMongoStop() async {
    await _loadPreferences();
    await _ensureDbConnection();
    var collection = db.collection('history');
    await collection.insertOne({
      'userid': _userId,
      'play': '',
      'pause': '',
      'stop': 'stop',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': DateTime.now().toIso8601String().split('T')[1],
    });
    var currentDate = DateTime.now().toIso8601String().split('T')[0];
    var currentTime = DateTime.now().toIso8601String().split('T')[1];
    await saveToCsv({
      'userid': _userId,
      'play': '',
      'pause': '',
      'stop': 'stop',
      'week': '',
      'date': currentDate,
      'time': currentTime,
    });
  }

  Future<void> insertMongoFinish() async {
    await _loadPreferences();
    await _ensureDbConnection();
    var collection = db.collection('week-finish');
    var currentDate = DateTime.now().toIso8601String().split('T')[0];
    var currentTime = DateTime.now().toIso8601String().split('T')[1];

    // Calculate the week number of the year
    int weekNumber = _getWeekNumber(DateTime.now());

    await collection.updateOne(
      {
        'userid': _userId,
        'date': currentDate,
      },
      {
        '\$set': {
          'week': weekNumber, // Store the week number of the year
          'time': currentTime,
        }
      },
      upsert: true,
    );

    await saveToCsv({
      'userid': _userId,
      'play': '',
      'pause': '',
      'stop': '',
      'week': weekNumber,
      'date': currentDate,
      'time': currentTime,
    });
  }

// Helper function to calculate the week number of the year
  int _getWeekNumber(DateTime date) {
    // Get the first day of the year
    DateTime startOfYear = DateTime(date.year, 1, 1);

    // Calculate the difference in days between date and startOfYear
    int daysDifference = date.difference(startOfYear).inDays;

    // Calculate and return the week number (starting from 1)
    return (daysDifference ~/ 7) + 1;
  }

  Future<void> _setAudioMain() async {
    await _audioPlayerMaster.setAsset('assets/audio/ambient_c_motion.mp3');
    _audioPlayerMaster.setVolume(_volumeMaster);
  }

  Duration get duration => _duration;
  Duration get position => _position;
  double get volume1 => _volumeMaster;

  void playPause() {
    if (isPlaying) {
      _audioPlayerMaster.pause();
      _insertMongoPause();
    } else {
      _audioPlayerMaster.play();
      _insertMongoStart();
    }
    isPlaying = !isPlaying;
    value = isPlaying; // Update Value Notifier
    notifyListeners();
  }

  void stop() async {
    await _audioPlayerMaster.stop();
    _setAudioMain();
    _position = Duration.zero; // Reset posisi audio
    isPlaying = false;
    value = false; // Update Value Notifier
    _insertMongoStop();
    notifyListeners();
  }

  void seek(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayerMaster.seek(position);
    if (!isPlaying) {
      await _audioPlayerMaster.play();
      isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> _loadVolume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _volumeMaster = prefs.getDouble('volumeMaster') ?? 1.0;
    _audioPlayerMaster.setVolume(_volumeMaster);
    notifyListeners();
  }

  void navigateToAudioSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioSelectionPage(
          onVolumeChanged: (double volume) async {
            setVolume(volume);
          },
        ),
      ),
    );
  }

  void setVolume(double volumeMaster) async {
    _volumeMaster = volumeMaster;
    _audioPlayerMaster.setVolume(volumeMaster);
    notifyListeners();
    await _saveVolume(); // Save volume to SharedPreferences
  }

  Future<void> _saveVolume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volumeMaster', _volumeMaster);
  }

  Future<void> loadAudio(String audioPath) async {
    await _audioPlayerMaster.setAsset(audioPath);
    _audioPlayerMaster.play();
    isPlaying = true;
    value = true; // Update Value Notifier
    notifyListeners();
  }

  void disposePlayer() {
    _audioPlayerMaster.dispose();
  }

  // void _onAudioComplete() async {
  //   print('Audio has finished playing');
  //   await insertMongoFinish();
  //   // Reset to initial state
  //   await _audioPlayerMaster.stop();
  //   _setAudioMain();
  //   _position = Duration.zero;
  //   isPlaying = false;
  //   value = false;
  //   notifyListeners();
  //   if (onAudioComplete != null) {
  //     onAudioComplete!();
  //   }
  //   _audioCompleted = false; // Reset the flag for future plays
  // }
  // -moty test

  void navigateToFinishedPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinishedPage(
          onFinishPressed: () async {
            await insertMongoFinish(); // Call the MongoDB insert function
            final currentDate = DateTime.now().toIso8601String().split('T')[0];
            final currentTime = DateTime.now().toIso8601String().split('T')[1];
            final weekNumber = _getWeekNumber(DateTime.now());

            await _saveOrUpdateCsv({
              'userid': _userId,
              'play': '',
              'pause': '',
              'stop': '',
              'week': weekNumber,
              'date': currentDate,
              'time': currentTime,
            });
          },
        ),
      ),
    );
  }

  Future<void> onAudioComplete2(BuildContext context) async {
    print('Audio has finished playing');
    // Reset to initial state
    await _audioPlayerMaster.stop();
    _setAudioMain();
    _position = Duration.zero;
    isPlaying = false; // Ensure isPlaying is set to false
    value = false; // Update ValueNotifier
    notifyListeners();

    if (onAudioComplete != null) {
      onAudioComplete!();
    }

    _audioCompleted = false; // Reset the flag for future plays

    // Navigate to FinishedPage
    navigateToFinishedPage(context);
  }

  // Method to toggle loop mode
  void toggleLoopMode() {
    if (_audioPlayerMaster.loopMode == LoopMode.one) {
      _audioPlayerMaster.setLoopMode(LoopMode.off);
    } else {
      _audioPlayerMaster.setLoopMode(LoopMode.one);
    }
  }
}
