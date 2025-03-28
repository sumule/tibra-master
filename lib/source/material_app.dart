import 'package:flutter/material.dart';
import 'player/player.dart';
import 'player/color.dart';

class TibraApp extends StatelessWidget {
  const TibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T I B R A',
            style: TextStyle(
              color: primaryColor,
              fontSize: 32,
            )),
        centerTitle: true,
        backgroundColor: secondaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.none,
            scale: 2.5, // 2x width and height
            alignment: Alignment.topCenter,
          ),
          // gradient: LinearGradient(
          //   colors: [secondaryColor, accentColor],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          //   stops: gradientstop,
        ),
        child: const Center(
          child:
              Player(), // Ensure Player widget is centered and takes up available space
        ),
      ),
    );
  }
}
