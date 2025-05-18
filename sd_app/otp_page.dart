import 'package:flutter/material.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String password;
  final String otp; // The OTP sent to the user

  const OtpPage({super.key, required this.email, required this.password, required this.otp});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_otpController.text.trim() == widget.otp) {
      // Create the user in Firebase Auth here
      try {
        // ...existing code to create user with widget.email and widget.password...
        // After successful sign up, navigate to login page
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        setState(() {
          _error = 'Failed to create account: $e';
        });
      }
    } else {
      setState(() {
        _error = 'Invalid OTP code';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Enter the OTP sent to ${widget.email}'),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'OTP'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: Text('Verify'),
                  ),
          ],
        ),
      ),
    );
  }
}
