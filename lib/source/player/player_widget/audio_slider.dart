import 'package:flutter/material.dart';
import 'audio_player_controller.dart';

class AudioSlider extends StatelessWidget {
  final AudioPlayerController controller;

  const AudioSlider({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: controller.position.inSeconds.toDouble(),
      min: 0,
      max: controller.duration.inSeconds.toDouble(),
      onChanged: (value) => controller.seek(value),
    );
  }
}
