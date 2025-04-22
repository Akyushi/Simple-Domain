import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'sign_up.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // To prevent multiple submissions
  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _authService.loginWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
            message = 'Invalid email or password';
            break;
          case 'user-disabled':
            message = 'This account has been disabled';
            break;
          default:
            message = 'Login failed. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }

      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const ClampingScrollPhysics(), // Smoother scrolling
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
                  'assets/icons/shopping-bag.svg', // Ensure the file path is correct
                  height: 80,
                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Login to Your Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) => 
                              value?.contains('@') ?? false ? null : 'Enter valid email',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword 
                                  ? Icons.visibility 
                                  : Icons.visibility_off),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          obscureText: !_showPassword,
                          autofillHints: const [AutofillHints.password],
                          validator: (value) => 
                              (value?.length ?? 0) > 5 ? null : 'Minimum 6 characters',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _showPassword,
                      onChanged: (value) => setState(() => _showPassword = value ?? false),
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SignUpPage(),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  child: const Text("Don't have an account? Create an Account"),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Sign in with Google'),
                  onPressed: () {},
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}