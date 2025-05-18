import 'package:cloud_functions/cloud_functions.dart';

class FirebaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<bool> sendOtp(String email, String otp) async {
    try {
      final callable = _functions.httpsCallable('sendOtp');
      final result = await callable.call({
        'email': email,
        'otp': otp,
      });
      return result.data['success'] ?? false;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }
} 