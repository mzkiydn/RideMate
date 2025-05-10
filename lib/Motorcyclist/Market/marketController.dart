import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class MarketController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

// Get all market products from many users except current user
  Future<List<Map<String, dynamic>>?> getAllMarketProducts() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return null;
      }

      QuerySnapshot query = await _firestore
          .collection('Market')
          .where('Owner', isNotEqualTo: userId)
          .get();

      if (query.docs.isEmpty) {
        print('No market products found');
        return null;
      }

      List<Map<String, dynamic>> marketProducts = [];
      for (var doc in query.docs) {
        // Add the Firestore document ID to the product data
        var productData = doc.data() as Map<String, dynamic>;
        productData['id'] = doc.id;  // Attach the document ID
        marketProducts.add(productData);
      }

      return marketProducts;
    } catch (e) {
      print('Error fetching all market products: $e');
      return null;
    }
  }

// Get the market products owned by the current user
  Future<List<Map<String, dynamic>>?> getOwnedMarketProducts() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return null;
      }

      QuerySnapshot query = await _firestore
          .collection('Market')
          .where('Owner', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) {
        print('No market products found for current user');
        return null;
      }

      List<Map<String, dynamic>> ownedMarketProducts = [];
      for (var doc in query.docs) {
        // Add the Firestore document ID to the product data
        var productData = doc.data() as Map<String, dynamic>;
        productData['id'] = doc.id;  // Attach the document ID
        ownedMarketProducts.add(productData);
      }

      return ownedMarketProducts;
    } catch (e) {
      print('Error fetching owned market products: $e');
      return null;
    }
  }

  // get market product by ID
  Future<Map<String, dynamic>?> getMarketProductById(String marketId) async {
    try {

      DocumentSnapshot<Map<String, dynamic>> query = await _firestore
          .collection('Market')
          .doc(marketId)
          .get();

      if (query.exists) {
        return query.data() as Map<String, dynamic>;
      }
      print('Market not found for ID: $marketId');
      return null;
    } catch (e) {
      print('Error fetching market product: $e');
      return null;
    }
  }

  // get owner detail
  Future<Map<String, dynamic>?> getOwnerDetails(String ownerId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('User').doc(ownerId).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print("Error fetching owner details: $e");
      return null;
    }
  }

  Future<void> checkAndRequestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) return;

    final result = await Permission.locationWhenInUse.request();

    if (!result.isGranted) {
      throw Exception('❌ Location permission not granted');
    }
  }

  // Create a new market product
  Future<void> createMarket(String name, String description, double price) async {
    try {
      // Ensure permission is granted
      await checkAndRequestLocationPermission();

      // Check if user is logged in
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get current date
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Save to Firestore
      DocumentReference docRef = await _firestore.collection('Market').add({
        'Name': name,
        'Description': description,
        'Price': price,
        'Owner': userId,
        'Date': currentDate,
        'Longitude': position.longitude,
        'Latitude': position.latitude,
      });

      print('Market product created successfully with ID: ${docRef.id}');
    } catch (e, stack) {
      print('Error creating market product: $e');
      print(stack);
    }
  }

  // update market product
  Future<void> updateMarket(String marketId, String name, String description, double price) async {
    try {
      await _firestore
          .collection('Market')
          .doc(marketId)
          .update({
        'Name': name,
        'Description': description,
        'Price': price,
      });

      print('Product updated successfully');
    } catch (e) {
      print('Error updating market product: $e');
    }
  }

  // delete market product
  Future<void> deleteMarket(String marketId) async {
    try {
      await _firestore
          .collection('Market')
          .doc(marketId)
          .delete();

      print('Market deleted successfully');
    } catch (e) {
      print('Error deleting market product: $e');
    }
  }

}
