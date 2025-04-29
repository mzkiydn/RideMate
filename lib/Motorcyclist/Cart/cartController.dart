import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> cartData = {};
  String userId = '';

  Future<void> initCart() async {
    userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) await fetchCartData();
  }

  Future<void> fetchCartData() async {
    if (userId.isEmpty) return;

    try {
      QuerySnapshot cartSnapshot = await _firestore
          .collection('Cart')
          .where('Owner', isEqualTo: userId)
          .where('Status', isEqualTo: 'In Cart')
          .get();

      Map<String, dynamic> groupedCart = {};

      for (var doc in cartSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String workshopId = data['Workshop'];

        if (!groupedCart.containsKey(workshopId)) {
          groupedCart[workshopId] = {
            'cartId': doc.id,
            'productQuantities': data['Products'] != null ? Map<String, int>.from(data['Products']) : {},
            'serviceIds': data['Services'] != null ? List<String>.from(data['Services']) : [],
            'totalPrice': (data['Price'] ?? 0.0).toDouble(),
          };

          DocumentSnapshot workshopDoc = await _firestore.collection('Workshop').doc(workshopId).get();
          if (workshopDoc.exists && workshopDoc.data() != null) {
            groupedCart[workshopId]['workshopName'] = (workshopDoc.data() as Map<String, dynamic>)['Name'];
          }
        }
      }

      cartData = groupedCart;
    } catch (e) {
      print("Error fetching cart: $e");
    }
  }

  Future<DocumentSnapshot> getProduct(String workshopId, String productId) {
    return _firestore.collection('Workshop').doc(workshopId).collection('Products').doc(productId).get();
  }

  Future<DocumentSnapshot> getService(String workshopId, String serviceId) {
    return _firestore.collection('Workshop').doc(workshopId).collection('Services').doc(serviceId).get();
  }

  Future<void> updateQuantity(
      String workshopId,
      String itemId,
      int change,
      Function setState,
      {bool isService = false, double price = 0.0}
      ) async {
    if (!cartData.containsKey(workshopId)) return;

    String cartId = cartData[workshopId]['cartId'];
    Map<String, int> productQuantities = Map.from(cartData[workshopId]['productQuantities']);
    List<String> serviceIds = List.from(cartData[workshopId]['serviceIds']);
    double totalPrice = cartData[workshopId]['totalPrice'];

    if (isService) {
      if (change < 0 && serviceIds.contains(itemId)) {
        serviceIds.remove(itemId);
        totalPrice -= price;
      }
    } else {
      if (productQuantities.containsKey(itemId)) {
        int newQuantity = productQuantities[itemId]! + change;

        // 🔥 Fetch Product Price (Ensure Correct Calculation)
        DocumentSnapshot productSnapshot = await getProduct(workshopId, itemId);
        if (productSnapshot.exists) {
          double productPrice = (productSnapshot['Price'] ?? 0.0).toDouble();

          if (newQuantity > 0) {
            productQuantities[itemId] = newQuantity;
            totalPrice += (productPrice * change);
          } else {
            productQuantities.remove(itemId);
            totalPrice -= productPrice; // Remove only once when qty = 0
          }
        }
      }
    }

    // 🔥 Debugging Logs to Check Values
    print("Updated Quantity: $productQuantities");
    print("Updated Total Price: $totalPrice");

    // 🔥 Update Local UI State First
    setState(() {
      cartData[workshopId]['productQuantities'] = productQuantities;
      cartData[workshopId]['serviceIds'] = serviceIds;
      cartData[workshopId]['totalPrice'] = totalPrice;
    });

    // 🔥 Ensure Firestore Update Happens After UI Update
    try {
      await _firestore.collection('Cart').doc(cartId).update({
        'Products': productQuantities,
        'Services': serviceIds,
        'Price': totalPrice,
      });
    } catch (e) {
      print("Error updating cart: $e");
    }
  }

  Future<void> markCartAsArrived(String workshopId, Function setStateCallback, BuildContext context) async {
    if (!cartData.containsKey(workshopId)) return;

    String cartId = cartData[workshopId]['cartId'];

    try {
      await FirebaseFirestore.instance.collection('Cart').doc(cartId).update({'Status': 'Arrived'});

      setStateCallback(() {
        cartData[workshopId]['Status'] = 'Arrived';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart status updated to Arrived!")),
      );
    } catch (e) {
      print("Error updating cart status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update cart status.")),
      );
    }
  }
}

