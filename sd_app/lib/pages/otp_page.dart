import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String password;
  final String otp; // The OTP sent to the user
  final String name; // <-- Add this
  final String? imagePath;

  const OtpPage({
    super.key,
    required this.email,
    required this.password,
    required this.otp,
    required this.name, // <-- Add this
    this.imagePath,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_otpController.text.trim() == widget.otp) {
      try {
        // Create the user in Firebase Auth
        final userCredential = await _authService.signUp(widget.email, widget.password, widget.name);
        final user = userCredential.user;
        String? photoUrl;
        if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
          // Upload image to Cloudinary
          final cloudName = 'dstlwxkdr';
          final uploadPreset = 'Unsigned';
          final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
          final request = http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(await http.MultipartFile.fromPath('file', widget.imagePath!));
          final response = await request.send();
          if (response.statusCode == 200) {
            final resStr = await response.stream.bytesToString();
            final resJson = json.decode(resStr);
            photoUrl = resJson['secure_url'];
          }
        } else {
          // Use default avatar asset path
          photoUrl = 'assets/images/user-avatar.png';
        }
        if (user != null) {
          await user.updatePhotoURL(photoUrl);
          // Save to Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'avatarUrl': photoUrl,
            'nickname': widget.name,
            'name': widget.name,
            'email': widget.email,
          }, SetOptions(merge: true));
        }
        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login page
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
      appBar: AppBar(
        title: const Text('Verify OTP'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the OTP sent to ${widget.email}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Verify'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
