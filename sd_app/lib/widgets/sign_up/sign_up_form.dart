import 'package:flutter/material.dart';

class SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showPassword;
  final Function(bool?) onShowPasswordChanged;

  const SignUpForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.showPassword,
    required this.onShowPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              autofillHints: const [AutofillHints.name],
              validator: (value) => value?.isNotEmpty ?? false ? null : 'Enter your name',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (value) => value?.contains('@') ?? false ? null : 'Enter valid email',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => onShowPasswordChanged(!showPassword),
                ),
              ),
              obscureText: !showPassword,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) {
                final password = value ?? '';
                List<String> errors = [];
                if (password.length < 8) {
                  errors.add('At least 8 characters');
                }
                if (!RegExp(r'[A-Z]').hasMatch(password)) {
                  errors.add('Include at least one uppercase letter');
                }
                if (!RegExp(r'[0-9]').hasMatch(password)) {
                  errors.add('Include at least one number');
                }
                if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>\[\]~_\-]').hasMatch(password)) {
                  errors.add('Include at least one symbol');
                }
                if (errors.isNotEmpty) {
                  return errors.join('\n');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: !showPassword,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  value == passwordController.text ? null : 'Passwords don\'t match',
            ),
          ],
        ),
      ),
    );
  }
}
