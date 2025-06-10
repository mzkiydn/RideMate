import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias Firebase's User class
import 'package:ridemate/Domain/User.dart';
import 'package:ridemate/Login/encryption_helper.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  bool isLocationEnabled = true; // Default to true

  // Fetch user data from Firestore
  Future<void> fetchUserData() async {
    try {

      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        currentUser = null; // No user session
        return;
      }
      print(uid);
      final userDoc = await FirebaseFirestore.instance.collection('User').doc(uid).get();
      print(userDoc.data());

      if (userDoc.exists) {
        currentUser = User.fromJson(userDoc.data() ?? {});
      } else {
        currentUser = null; // Handle case where user document is missing
      }
    } catch (e) {
      print('Error fetching user data: $e');
      currentUser = null; // Handle errors gracefully
    }
  }

  // Toggle location setting
  void toggleLocation(bool isEnabled) {
    isLocationEnabled = isEnabled;
  }

  // update account
  Future<String?> updateUserProfile({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String currentUsername,
    required String newUsername,
    required String name,
    required String address,
    required String birthDate,
    required String phoneNumber,
  }) async {
    if (newUsername != currentUsername) {
      final existing = await _firestore
          .collection('User')
          .where('Username', isEqualTo: newUsername)
          .get();
      if (existing.docs.isNotEmpty) return 'Username already taken.';
    }
    if (!isValidDate(birthDate)) return 'Invalid birth date format or future date.';
    if (newPassword.isNotEmpty && !isValidPassword(newPassword)) {
      return 'Password must be at least 6 characters, with 1 capital & 1 number.';
    } else if (newPassword == currentPassword && newPassword.isNotEmpty){
      print(newPassword);
      print(currentPassword);
      return 'New password must be different from the current password';
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('User').doc(userId).get();
      if (!userDoc.exists) return 'User not found.';

      String storedEncryptedPassword = userDoc['Password'];
      String decryptedPassword = EncryptionHelper.decryptText(storedEncryptedPassword);

      if (currentPassword != decryptedPassword) return 'Please enter your current password.';

      final updates = {
        'Username': newUsername,
        'Name': name,
        'Address': address,
        'Birth Date': birthDate,
        'Phone Number': phoneNumber,
      };

      if (newPassword.isNotEmpty) {
        final encryptedNewPassword = EncryptionHelper.encryptText(newPassword);
        updates['Password'] = encryptedNewPassword;

        // Update Firebase Auth password
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(newPassword);
        }
      }

      await _firestore.collection('User').doc(userId).update(updates);
      return null;
    } catch (e) {
      return 'Error updating profile: ${e.toString()}';
    }
  }

  // Handle logout logic
  void logout() {
    firebase_auth.FirebaseAuth.instance.signOut();
    print("User logged out");
  }

  // Handle option selection logic
  void onOptionTapped(String option) {
    print("$option tapped");
  }

  bool isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$');
    return regex.hasMatch(password);
  }
  bool isValidDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return parsed.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

}
