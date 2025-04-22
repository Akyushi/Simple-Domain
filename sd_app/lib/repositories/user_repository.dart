import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  // Create a new user in Firestore
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      print("Error creating user: $e");
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      var snapshot = await _firestore.collection('users').doc(uid).get();
      return snapshot.data();
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUser(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).update(userData);
    } catch (e) {
      print("Error updating user data: $e");
      rethrow;
    }
  }

  // Delete user data from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }
}
