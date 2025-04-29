import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridemate/Domain/Cart.dart';

class ServiceController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all workshops from Firestore
  Future<List<Map<String, dynamic>>> getWorkshops() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Workshop').get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'Name': doc['Name'],
          'Operating Hours': doc['Operating Hours'], // Modify this if needed
          'Contact': doc['Contact'],
          'Rating': doc['Rating'],
          'Latitude': doc['Latitude'],
          'Longitude': doc['Longitude'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching workshops: $e');
      return [];
    }
  }

  // fetch all products
  Future<List<Map<String, dynamic>>> fetchProducts(String workshopId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id, // Store the product ID
          ...doc.data() as Map<String, dynamic>, // Merge with product attributes
        };
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // fetch all services
  Future<List<Map<String, dynamic>>> fetchServices(String workshopId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id, // Store the product ID
          ...doc.data() as Map<String, dynamic>, // Merge with product attributes
        };
      }).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Function to handle search action (expand functionality as needed)
  void onSearch() {
    print("Search button pressed");
  }

  // // create/update cart for product
  // Future<void> addToCart({
  //   required String workshopId,
  //   String? productId,
  //   int quantity = 1,
  //   double? productPrice,
  //   String? serviceId,
  //   double? servicePrice,
  // }) async {
  //   try {
  //     String userId = _auth.currentUser?.uid ?? '';
  //     if (userId.isEmpty) {
  //       print("User not logged in");
  //       return;
  //     }
  //
  //     CollectionReference cartCollection = _firestore.collection('Cart');
  //
  //     // Check if a cart exists for this user and workshop with "In Cart" or "Arrive" status
  //     QuerySnapshot existingCartQuery = await cartCollection
  //         .where('Owner', isEqualTo: userId)
  //         .where('Workshop', isEqualTo: workshopId)
  //         .where('Status', whereIn: ["In Cart", "Arrive"])
  //         .limit(1)
  //         .get();
  //
  //     if (existingCartQuery.docs.isNotEmpty) {
  //       // Update existing cart
  //       DocumentSnapshot cartDoc = existingCartQuery.docs.first;
  //       Map<String, dynamic> existingData = cartDoc.data() as Map<String, dynamic>;
  //
  //       // Get current products and services
  //       Map<String, int> productQuantities = Map<String, int>.from(existingData['Products'] ?? {});
  //       List<String> serviceIds = List<String>.from(existingData['Services'] ?? []);
  //
  //       double newTotalPrice = existingData['Price'] ?? 0;
  //
  //       if (productId != null && productPrice != null) {
  //         // Update product quantity
  //         productQuantities.update(productId, (existingQty) => existingQty + quantity, ifAbsent: () => quantity);
  //         newTotalPrice += productPrice * quantity;
  //       }
  //
  //       if (serviceId != null && servicePrice != null) {
  //         // Add service if not already in the list
  //         if (!serviceIds.contains(serviceId)) {
  //           serviceIds.add(serviceId);
  //           newTotalPrice += servicePrice;
  //         }
  //       }
  //
  //       await cartDoc.reference.update({
  //         'Products': productQuantities,
  //         'Services': serviceIds,
  //         'Price': newTotalPrice,
  //       });
  //
  //       print("Cart updated successfully");
  //     } else {
  //       // Create a new cart
  //       DocumentReference newCartRef = cartCollection.doc();
  //
  //       Map<String, int> productQuantities = {};
  //       List<String> serviceIds = [];
  //
  //       double totalPrice = 0;
  //
  //       if (productId != null && productPrice != null) {
  //         productQuantities[productId] = quantity;
  //         totalPrice += productPrice * quantity;
  //       }
  //
  //       if (serviceId != null && servicePrice != null) {
  //         serviceIds.add(serviceId);
  //         totalPrice += servicePrice;
  //       }
  //
  //       Cart newCart = Cart(
  //         id: newCartRef.id,
  //         userId: userId,
  //         workshopId: workshopId,
  //         productQuantities: productQuantities,
  //         serviceIds: serviceIds,
  //         status: "In Cart",
  //         totalPrice: totalPrice,
  //       );
  //
  //       await newCartRef.set(newCart.toMap());
  //       print("New cart created successfully");
  //     }
  //   } catch (e) {
  //     print("Error adding to cart: $e");
  //   }
  // }


}
