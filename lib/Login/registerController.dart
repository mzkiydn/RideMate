import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Rename FirebaseUser to firebase_auth.User
import 'package:ridemate/Domain/User.dart';  // Import custom User domain model

class RegisterController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // Processing icon
  void toggleLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    required String name,
    required String address,
    required String birthDate,
    required String phoneNumber,
    required String userType,
  }) async {

    // Validation
    if (username.isEmpty || email.isEmpty || password.isEmpty || name.isEmpty || userType.isEmpty) {
      return 'Please fill all required fields.';
    }
    if (!_isValidEmail(email)) {
      return 'Invalid email format.';
    }
    if (!_isValidPassword(password)) {
      return 'Invalid password format.';
    }
    if (!_isValidDate(birthDate)) {
      return 'Invalid birth date format. Use YYYY-MM-DD.';
    }

    try {
      toggleLoading(true);

      // Create Firebase Auth user
      firebase_auth.UserCredential userCredential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String userId = userCredential.user!.uid;

      // Create User object using the User domain
      User user = User(
        userID: userId,
        username: username,
        password: password,
        email: email,
        name: name,
        address: address,
        birthDate: birthDate,
        pNum: phoneNumber,
        userType: userType,
        rating: userType == 'Mechanic' ? 5.0 : null,
      );

      // Save User object to Firestore
      await _firestore.collection('User').doc(userId).set(user.toJson());

      return null; // No error, registration successful
    } catch (e) {
      return 'Error: ${e.toString()}';
    } finally {
      toggleLoading(false);
    }
  }

  // Text Field format
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }
  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$');
    return regex.hasMatch(password);
  }
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return regex.hasMatch(date);
  }
}
