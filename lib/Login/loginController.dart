import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    try {
      // Fetch email linked to the username from Firestore
      String? email = await _getEmailFromUsername(username);
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
        return;
      }

      print('Email found: $email');  // Debugging log

      // Sign in using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print('User signed in: ${userCredential.user?.email}'); // Debugging log

      if (userCredential.user != null) {
        // Now fetch user data from Firestore (Check user document)
        String userId = userCredential.user!.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(userId)
            .get();

        // Ensure the document exists and handle the response
        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          print('User data: $userData');  // Debugging log

          // Validate the data structure before using it
          if (userData.containsKey('User ID')) {
            // Proceed to the next screen
            Navigator.pushNamed(context, '/feed');
          } else {
            throw Exception('Invalid user data format');
          }
        } else {
          throw Exception('User document not found');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }
    } catch (e) {
      print('Login failed: $e');  // Debugging log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
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
          print('User data: $userDoc');  // Debugging log
          return userDoc['Email']; // Ensure you're accessing 'Email' correctly
        }
      }
    } catch (e) {
      print('Error fetching email: $e');
    }
    return null;
  }

  // Function to check if the user exists in Firebase Authentication
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
