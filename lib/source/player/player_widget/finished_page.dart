import 'dart:async';
import 'package:flutter/material.dart';
import '../color.dart';

class FinishedPage extends StatefulWidget {
  final Future<void> Function() onFinishPressed;

  const FinishedPage({Key? key, required this.onFinishPressed})
      : super(key: key);

  @override
  _FinishedPageState createState() => _FinishedPageState();
}

class _FinishedPageState extends State<FinishedPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Automatically close the page after 5 minutes
    _timer = Timer(const Duration(minutes: 5), () {
      Navigator.pop(
          context); // Close the page without sending anything to MongoDB
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Selesai',
          style: TextStyle(color: primaryColor, fontSize: 32),
        ),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Terima Kasih!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda telah menyelesaikan tugas ini.',
                style: TextStyle(
                  fontSize: 18,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                ),
                onPressed: () async {
                  await widget
                      .onFinishPressed(); // Call the function to insert into MongoDB
                  Navigator.pop(context); // Close the page
                },
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
