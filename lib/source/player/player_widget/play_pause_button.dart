import 'package:flutter/material.dart';
import 'audio_player_controller.dart';
import '../color.dart';

class PlayPauseButton extends StatelessWidget {
  final AudioPlayerController controller;

  const PlayPauseButton({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (context, isPlaying, child) {
        return IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 128,
          color: primaryColor,
          onPressed: controller.playPause,
        );
      },
    );
  }
}
