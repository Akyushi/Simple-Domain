import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../widgets/sign_up/sign_up_form.dart';
import '../pages/otp_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      // Use googleUser.email for display or further processing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signed in as ${googleUser.email}"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the home page or perform additional actions
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/icons/logo.svg',
                  height: 80,
                  placeholderBuilder: (context) =>
                      const CircularProgressIndicator(),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Create Your Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                SignUpForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  showPassword: _showPassword,
                  onShowPasswordChanged: (value) => setState(() => _showPassword = value ?? false),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _showPassword,
                      onChanged: (value) =>
                          setState(() => _showPassword = value ?? false),
                    ),
                    const Text('Show Password'),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: const Text(
                    'SIGN UP',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginPage(),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  child: const Text("Already have an account? Log In"),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Sign up with Google'),
                  onPressed: _handleGoogleSignIn,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Designed by Simple Developers',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Creating account..."),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _showLoadingDialog();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Generate a 6-digit OTP
      final otp = (Random().nextInt(900000) + 100000).toString(); 

      // Send OTP to user's email (implement this function)
      await _sendOtpToEmail(email, otp);

      Navigator.of(context).pop(); // Close loading dialog

      // Navigate to OTP verification page, pass email, password, name, and otp
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: email,
            password: password,
            otp: otp,
            name: _nameController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog on error
      String errorMessage = e.toString();
      if (errorMessage.contains('network-request-failed')) {
        errorMessage = "Network error: Please check your internet connection.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Use Firebase Cloud Function to send OTP to user's email
  Future<void> _sendOtpToEmail(String email, String otp) async {
    final success = await sendOtpWithEmailJS(toEmail: email, otp: otp);
    if (!success) {
      throw Exception('Failed to send OTP email');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

Future<bool> sendOtpWithEmailJS({
  required String toEmail,
  required String otp,
}) async {
  const serviceId = 'service_fqf04zg';
  const templateId = 'template_94sl2we';
  const userId = 'jUAiAXwg8LaI98Ur9';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost', // or your app's domain
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'email': toEmail,
        'passcode': otp,
        'time': '15 minutes',
      }
    }),
  );

  return response.statusCode == 200;
}

Future<String?> uploadImageToCloudinary(File imageFile) async {
  final cloudName = 'YOUR_CLOUD_NAME';
  final uploadPreset = 'YOUR_UNSIGNED_UPLOAD_PRESET';

  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    final resStr = await response.stream.bytesToString();
    final resJson = json.decode(resStr);
    return resJson['secure_url']; // This is the image URL
  } else {
    print('Failed to upload image: ${response.statusCode}');
    return null;
  }
}
