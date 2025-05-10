import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/Login/encryption_helper.dart';

class LoginController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // Step 1: Get the user from Firestore using username
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('Username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username not found')),
        );
        return;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;
      final storedEmail = userData['Email'];
      final encryptedPassword = userData['Password'];
      final firestoreUserId = userDoc.id;

      // Step 2: Decrypt and validate password manually
      final decryptedPassword = EncryptionHelper.decryptText(encryptedPassword);
      print("Password: $decryptedPassword");
      if (decryptedPassword != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')),
        );
        return;
      }

      // Step 3: Authenticate using Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: storedEmail, password: password);

      final firebaseUid = userCredential.user?.uid;

      // Step 4: Sync Firestore UID with Firebase UID
      if (firebaseUid != userData['User ID']) {
        await FirebaseFirestore.instance
            .collection('User')
            .doc(firestoreUserId)
            .update({'User ID': firebaseUid});
      }

      // Step 5: Navigate to dashboard
      Navigator.pushNamed(context, '/feed');
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: ${e.toString()}')),
      );
    }
  }

  Future<String?> _getEmailFromUsername(String username) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('Username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var userDoc = snapshot.docs.first.data();
        if (userDoc is Map<String, dynamic>) {
          return userDoc['Email'];
        }
      }
    } catch (e) {
      print('Error fetching email: $e');
    }
    return null;
  }

  Future<void> checkIfUserExists(String email) async {
    try {
      List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        print("User exists in Firebase Authentication");
      } else {
        print("No account found with this email");
      }
    } catch (e) {
      print('Error checking if user exists: $e');
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    final String username = usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your username')),
      );
      return;
    }

    String? email = await _getEmailFromUsername(username);
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username not found')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
