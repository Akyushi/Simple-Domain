import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  File? _profileImageFile;

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google authentication failed');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        // Check if user already exists in Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Only set data if user doesn't exist
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'nickname': googleUser.displayName,
            'avatarUrl': googleUser.photoUrl,
            'email': googleUser.email,
          }, SetOptions(merge: true));
          
          // Update Auth profile only for new users
          await user.updateDisplayName(googleUser.displayName);
          await user.updatePhotoURL(googleUser.photoUrl);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signed in as ${userCredential.user?.email}"),
          backgroundColor: Colors.green,
        ),
      );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/logo.svg',
                      height: 40,
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Your Account',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImageFile != null
                        ? FileImage(_profileImageFile!)
                        : const AssetImage('assets/images/user-avatar.png') as ImageProvider,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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

      // Pass the image file path (if any) or null
      final imagePath = _profileImageFile?.path;

      // Navigate to OTP verification page, pass email, password, name, otp, and imagePath
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: email,
            password: password,
            otp: otp,
            name: _nameController.text.trim(),
            imagePath: imagePath,
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      print('Sign up failed: \\${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: $e'),
          backgroundColor: Colors.redAccent,
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
  const templateId = 'template_dfaj3n9';
  const userId = 'jUAiAXwg8LaI98Ur9';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  try {
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
    print('EmailJS response: \\${response.statusCode} \\${response.body}');
    if (response.statusCode != 200) {
      print('EmailJS error: Status code: \\${response.statusCode}, Body: \\${response.body}');
    }
    return response.statusCode == 200;
  } catch (e) {
    print('Exception sending OTP with EmailJS: \\${e.toString()}');
    return false;
  }
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
