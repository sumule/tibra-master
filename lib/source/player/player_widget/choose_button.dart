import 'package:flutter/material.dart';
import 'audio_player_controller.dart';
import '../color.dart';

class ChooseButton extends StatelessWidget {
  final AudioPlayerController controller;

  const ChooseButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // icon: const Icon(Icons.music_note),
      icon: const Icon(Icons.volume_up),
      iconSize: 96,
      color: primaryColor,
      onPressed: () {
        controller.navigateToAudioSelection(context);
      },
    );
  }
}
