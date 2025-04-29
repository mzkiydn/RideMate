import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias Firebase's User class
import 'package:ridemate/Domain/User.dart';

class ProfileController {
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

      final userDoc = await FirebaseFirestore.instance.collection('User').doc(uid).get();

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

  // Handle logout logic
  void logout() {
    firebase_auth.FirebaseAuth.instance.signOut();
    print("User logged out");
  }

  // Handle option selection logic
  void onOptionTapped(String option) {
    print("$option tapped");
  }
}
