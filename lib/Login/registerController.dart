import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:ridemate/Domain/User.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:ridemate/Login/encryption_helper.dart';

class RegisterController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // Encryptor setup
  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows!'); // Use secure key in real apps
  final _iv = encrypt.IV.fromLength(16);

  void toggleLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String encryptPassword(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.encrypt(plainText, iv: _iv).base64;
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
    if (username.isEmpty || email.isEmpty || password.isEmpty || name.isEmpty || userType.isEmpty) {
      return 'Please fill all required fields.';
    }
    if (!_isValidEmail(email)) return 'Invalid email format.';
    if (!_isValidPassword(password)) return 'Password must be at least 6 characters, with 1 capital & 1 number.';
    if (!_isValidDate(birthDate)) return 'Invalid birth date format or future date. Use YYYY-MM-DD.';

    try {
      toggleLoading(true);

      // Check username uniqueness
      var existing = await _firestore.collection('User')
          .where('Username', isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) return 'Username is already taken.';

      // Step 1: Register user in Firebase Auth
      final authCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUid = authCredential.user!.uid;

      // Step 2: Encrypt password for storage
      String encryptedPassword = EncryptionHelper.encryptText(password);

      // Step 3: Store user details in Firestore
      User user = User(
        userID: firebaseUid,
        username: username,
        password: encryptedPassword,
        email: email,
        name: name,
        address: address,
        birthDate: birthDate,
        pNum: phoneNumber,
        userType: userType,
        rating: userType == 'Mechanic' ? 5.0 : null,
      );

      await _firestore.collection('User').doc(firebaseUid).set(user.toJson());

      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered with Firebase Authentication.';
      }
      return 'Firebase Auth Error: ${e.message}';
    } catch (e) {
      return 'Error: ${e.toString()}';
    } finally {
      toggleLoading(false);
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$');
    return regex.hasMatch(password);
  }

  bool _isValidDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return parsed.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
