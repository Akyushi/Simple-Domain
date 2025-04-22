import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  AuthService() : _userRepository = UserRepository(FirebaseFirestore.instance);

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Stream of User? to track auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user with email/password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Add user details to Firestore in the 'users' collection
        await _userRepository.createUser(user.uid, {
          'uid': user.uid,
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userType': 'buyer', // Default user type
          'emailVerified': false,
          'profileImageUrl': '', // Placeholder for profile image
        });

        // Send email verification
        await user.sendEmailVerification();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during sign up: ${e.code} - ${e.message}");
      rethrow; // Rethrow to handle in UI
    } catch (e) {
      print("General Error during sign up: $e");
      rethrow;
    }
  }

  // Log in with email and password
  Future<User?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // You might want to check if email is verified here
      // if (!result.user!.emailVerified) {
      //   await _auth.signOut();
      //   throw FirebaseAuthException(
      //     code: 'email-not-verified',
      //     message: 'Please verify your email first',
      //   );
      // }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during login: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("General Error during login: $e");
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot snapshot = 
          await _firestore.collection('users').doc(uid).get();
      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating user data: $e");
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error sending password reset email: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();
        // Then delete the user account
        await user.delete();
      }
    } catch (e) {
      print("Error deleting account: $e");
      rethrow;
    }
  }
}