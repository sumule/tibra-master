import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'material_app.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  Future<void> _saveUserId() async {
    final userIdFull = _controller.text;
    if (_isValidUserId(userIdFull)) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = userIdFull.substring(userIdFull.length - 2);
      await prefs.setString('userid', userId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TibraApp()),
      );
    } else {
      setState(() {
        _errorMessage = 'Contact Us for get your userID';
      });
    }
  }

  bool _isValidUserId(String userId) {
    final regex = RegExp(r'^1314372\d{2}$');
    return regex.hasMatch(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter User ID',
                errorText: _errorMessage,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveUserId,
              child: const Text('Save User ID'),
            ),
          ],
        ),
      ),
    );
  }
}
