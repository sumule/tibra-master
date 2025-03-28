import 'package:flutter/material.dart';
import 'audio_player_controller.dart';
import '../color.dart';

class StopButton extends StatelessWidget {
  final AudioPlayerController controller;

  const StopButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.stop),
      iconSize: 128,
      color: primaryColor,
      onPressed: controller.stop,
    );
  }
}
