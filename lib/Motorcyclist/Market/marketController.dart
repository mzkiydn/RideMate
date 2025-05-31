import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class MarketController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch all market products that are NOT owned by the current user
  Future<List<Map<String, dynamic>>?> getAllMarketProducts() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      QuerySnapshot query = await _firestore
          .collection('Market')
          .where('Owner', isNotEqualTo: userId)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching all market products: $e');
      return null;
    }
  }

  /// Fetch market products owned by current user
  Future<List<Map<String, dynamic>>?> getOwnedMarketProducts() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      QuerySnapshot query = await _firestore
          .collection('Market')
          .where('Owner', isEqualTo: userId)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching owned market products: $e');
      return null;
    }
  }

  /// Fetch a single market product by its document ID
  Future<Map<String, dynamic>?> getMarketProductById(String marketId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection('Market').doc(marketId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error fetching market product: $e');
      return null;
    }
  }

  /// Get user details for a given owner ID from the 'User' collection
  Future<Map<String, dynamic>?> getOwnerDetails(String ownerId) async {
    try {
      final userDoc = await _firestore.collection('User').doc(ownerId).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print("Error fetching owner details: $e");
      return null;
    }
  }

  /// Check and request location permission
  Future<void> checkAndRequestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return;

    final result = await Permission.locationWhenInUse.request();
    if (!result.isGranted) {
      throw Exception('❌ Location permission not granted');
    }
  }

  /// Create a new market product entry
  /// Optional: pass an existing Base64 image string or pick & convert image from gallery
  Future<void> createMarket(String name, String description, double price, {String? base64Image}) async {
    try {
      await checkAndRequestLocationPermission();

      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Use provided base64 image string or let user pick and convert image
      // String? finalBase64Image = base64Image ?? await pickAndConvertImageToBase64();

      // Get current device location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore.collection('Market').add({
        'Name': name,
        'Description': description,
        'Price': price,
        'Owner': userId,
        'Date': currentDate,
        'Longitude': position.longitude,
        'Latitude': position.latitude,
        'Image': base64Image ?? '',
      });

      print('✅ Market product created successfully');
    } catch (e, stack) {
      print('❌ Error creating market product: $e');
      print(stack);
    }
  }

  /// Update an existing market product by document ID
  Future<void> updateMarket(String marketId, String name, String description, double price, {String? base64Image}) async {
    try {
      Map<String, dynamic> updateData = {
        'Name': name,
        'Description': description,
        'Price': price,
      };

      if (base64Image != null) {
        updateData['Image'] = base64Image;
      }

      await _firestore.collection('Market').doc(marketId).update(updateData);
      print('✅ Product updated successfully');
    } catch (e) {
      print('❌ Error updating market product: $e');
    }
  }

  /// Delete a market product by document ID
  Future<void> deleteMarket(String marketId) async {
    try {
      await _firestore.collection('Market').doc(marketId).delete();
      print('✅ Market product deleted successfully');
    } catch (e) {
      print('❌ Error deleting market product: $e');
    }
  }

  /// Pick image from gallery and convert to Base64 string
  /// Returns Base64 string or null if no image selected or error
  Future<String?> pickAndConvertImageToBase64() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        print("❌ No image selected.");
        return null;
      }

      File imageFile = File(pickedFile.path);

      if (!await imageFile.exists()) {
        print("❌ File does not exist at ${pickedFile.path}");
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      String base64String = base64Encode(bytes);

      print("✅ Image converted to Base64 successfully.");

      return base64String;
    } catch (e) {
      print('❌ Error converting image to Base64: $e');
      return null;
    }
  }

  /// Convert a base64 string back to bytes (optional utility)
  Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('❌ Error decoding Base64 string: $e');
      return null;
    }
  }
}
