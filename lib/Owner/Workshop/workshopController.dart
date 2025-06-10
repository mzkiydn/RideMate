import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkshopController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;  // Instance of FirebaseAuth

  // Check if the user is a workshop owner
  Future<bool> _isWorkshopOwner(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('User').doc(userId).get();
      if (userDoc.exists) {
        String userType = userDoc['Type'] ?? ''; // Assuming 'UserType' is stored in Users collection
        return userType == 'Workshop Owner';
      }
    } catch (e) {
      print('Error checking user type: $e');
    }
    return false;
  }

  // Add a new workshop with owner ID as the user session ID
  Future<void> addWorkshop(String name, String operatingHours, String contactNumber, double latitude, double longitude) async {
    try {
      // Get the current user session ID (UID)
      String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        print('No user logged in');
        return;
      }

      bool isOwner = await _isWorkshopOwner(userId);
      if (!isOwner) {
        print('Access denied: Only workshop owners can add workshops');
        return;
      }

      // Create a new workshop document in Firestore
      DocumentReference workshopRef = await _firestore.collection('Workshop').add({
        'Name': name,
        'Operating Hours': operatingHours,
        'Contact': contactNumber,
        'Rating': 5.0,
        'Latitude': latitude,
        'Longitude': longitude,
        'Owner': userId,  // Store the user session ID as OwnerId
      });

      // Create empty subcollections for Products, Services, and Shifts
      await workshopRef.collection('Products').doc();  // Create an empty document in Products
      await workshopRef.collection('Services').doc();  // Create an empty document in Services
      await workshopRef.collection('Shifts').doc();  // Create an empty document in Shifts

      print('Workshop added with ID: ${workshopRef.id}');
    } catch (e) {
      print('Error adding workshop: $e');
    }
  }

  // Update an existing workshop by ID
  Future<void> updateWorkshop(String id, String name, String operatingHours, String contactNumber, double latitude, double longitude) async {
    try {

      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      bool isOwner = await _isWorkshopOwner(userId);
      if (!isOwner) {
        print('Access denied: Only workshop owners can update workshops');
        return;
      }

      // Update the workshop document in Firestore
      await _firestore.collection('Workshop').doc(id).update({
        'Name': name,
        'Operating Hours': operatingHours,
        'Contact': contactNumber,
        'Latitude': latitude,
        'Longitude': longitude,
      });

      print('Workshop updated with ID: $id');
    } catch (e) {
      print('Error updating workshop: $e');
    }
  }

  // Delete a workshop by ID
  Future<void> deleteWorkshop(String id) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      bool isOwner = await _isWorkshopOwner(userId);
      if (!isOwner) {
        print('Access denied: Only workshop owners can delete workshops');
        return;
      }

      // Delete the workshop document from Firestore
      await _firestore.collection('Workshop').doc(id).delete();
      print('Workshop deleted with ID: $id');
    } catch (e) {
      print('Error deleting workshop: $e');
    }
  }

  // Get all workshops owned by the current user
  Future<List<Map<String, dynamic>>> getWorkshops() async {
    try {
      // Get the current user session ID (UID)
      String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        print('No user logged in');
        return [];
      }

      // Query Firestore to get only workshops owned by the current user
      QuerySnapshot querySnapshot = await _firestore.collection('Workshop')
          .where('Owner', isEqualTo: userId)  // Filter by OwnerId
          .get();

      // Convert Firestore documents to a list of maps
      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'Name': doc['Name'],
          'Operating Hours': doc['Operating Hours'],
          'Contact': doc['Contact'],
          'Rating': doc['Rating'],
          'Latitude': doc['Latitude'],
          'Longitude': doc['Longitude'],
        };
      }).toList();
    } catch (e) {
      print('Error getting workshops: $e');
      return [];
    }
  }

  // Get a specific workshop by ID (owner-specific)
  Future<Map<String, dynamic>> getWorkshopById(String id) async {
    try {
      // Get the current user session ID (UID)
      String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        print('No user logged in');
        return {};
      }

      DocumentSnapshot doc = await _firestore.collection('Workshop').doc(id).get();

      if (doc.exists && doc['Owner'] == userId) {  // Check if the workshop belongs to the current user
        return {
          'id': doc.id,
          'Name': doc['Name'],
          'Operating Hours': doc['Operating Hours'],
          'Contact': doc['Contact'],
          'Rating': doc['Rating'],
          'Latitude': doc['Latitude'],
          'Longitude': doc['Longitude'],
        };
      } else {
        print('Workshop not found or does not belong to the current user');
        return {};
      }
    } catch (e) {
      print('Error getting workshop: $e');
      return {};
    }
  }
}
