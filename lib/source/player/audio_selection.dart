import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSelectionPage extends StatefulWidget {
  final Function(double) onVolumeChanged;
  const AudioSelectionPage({super.key, required this.onVolumeChanged});
  @override
  _AudioSelectionPageState createState() => _AudioSelectionPageState();
}

class _AudioSelectionPageState extends State<AudioSelectionPage> {
  double _currentVolume = 0.5;
  @override
  void initState() {
    super.initState();
    _loadVolume();
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentVolume = prefs.getDouble('volumeMaster') ?? 0.5;
    });
  }

  Future<void> _saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volumeMaster', volume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Volume'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Adjust Volume'),
            Slider(
              value: _currentVolume,
              min: 0.0,
              max: 1.0,
              onChanged: (double value) {
                setState(() {
                  _currentVolume = value;
                });
                widget.onVolumeChanged(value);
                _saveVolume(value);
              },
            ),
            Text('Volume: ${(_currentVolume * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}
