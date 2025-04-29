import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? workedWorkshopId;
  String? workedWorkshopName;
  Map<String, dynamic> cartDetails = {};
  Map<String, Map<String, dynamic>> assignedCarts = {};
  Map<String, Map<String, dynamic>> workingCarts = {};
  Map<String, dynamic> cartData = {};

  Future<void> initAssignData() async {
    print("Entering initAssignData()");
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      await fetchShiftWorkshop(userId);
      await fetchAssignedCarts();
      await fetchWorkingCarts();
    }
    print("Exiting initAssignData()");
  }

  // from shift, find workshop with status in shift (compare date and time), then get the workshop id
  Future<void> fetchShiftWorkshop(String userId) async {
    print("Entering fetchShiftWorkshop()");

    var snapshot = await _firestore.collectionGroup('Shifts').get();

    for (var shiftDoc in snapshot.docs) {
      var applicants = shiftDoc.data()['Applicant'] as List<dynamic>?;

      if (applicants != null) {
        for (var applicant in applicants) {
          if (applicant['id'] == userId && applicant['Status'] == 'In Shift') {
            var workshopRef = shiftDoc.reference.parent.parent; // Get parent workshop

            if (workshopRef != null) {
              var workshopSnapshot = await workshopRef.get();
              if (workshopSnapshot.exists) {
                var data = workshopSnapshot.data() as Map<String, dynamic>;
                workedWorkshopId = workshopRef.id;
                workedWorkshopName = data['Name'] ?? 'Unknown Workshop';

                print("Fetched shift workshop: ID = $workedWorkshopId, Name = $workedWorkshopName");
                print("Exiting fetchShiftWorkshop()");
                return; // Exit function after finding the first match
              }
            }
          }
        }
      }
    }

    print("No matching shift found for user.");
    print("Exiting fetchShiftWorkshop()");
  }

// Fetch assigned carts
  Future<void> fetchAssignedCarts() async {
    print("Entering fetchAssignedCarts()");
    if (workedWorkshopId == null) {
      print("Workshop not found. Exiting fetchAssignedCarts().");
      return;
    }

    String userId = _auth.currentUser?.uid ?? '';
    var snapshot = await _firestore
        .collection('Cart')
        .where('Workshop', isEqualTo: workedWorkshopId)
        .where('Mechanic', isEqualTo: userId)
        .where('Status', whereIn: ['Assigned'])
        .get();

    assignedCarts = {};

    for (var doc in snapshot.docs) {
      var cartData = doc.data();
      String? ownerId = cartData['Owner'];
      String? assignedMechanicId = cartData['Mechanic'];

      // Debugging prints
      print("Cart ID: ${doc.id}, Owner ID: $ownerId, Assigned Mechanic ID: $assignedMechanicId");

      // Fetch owner details
      String? ownerName = ownerId != null ? await fetchUserName(ownerId) : "Unknown Owner";

      // Fetch mechanic details
      String? mechanicName = assignedMechanicId != null ? await fetchUserName(assignedMechanicId) : "Unknown Mechanic";

      // Debugging prints
      print("Cart ID: ${doc.id}, Mechanic Name: $mechanicName");

      assignedCarts[doc.id] = {
        ...cartData,
        'OwnerName': ownerName,      // Store owner name
        'MechanicName': mechanicName // Store mechanic name
      };
    }

    print("Fetched assigned carts: $assignedCarts");
    print("Exiting fetchAssignedCarts()");
  }

// Fetch working cart
  Future<void> fetchWorkingCarts() async {
    print("Entering fetchWorkingCarts()");
    if (workedWorkshopId == null) {
      print("Workshop not found. Exiting fetchWorkingCarts().");
      return;
    }

    String userId = _auth.currentUser?.uid ?? '';
    var snapshot = await _firestore
        .collection('Cart')
        .where('Workshop', isEqualTo: workedWorkshopId)
        .where('Mechanic', isEqualTo: userId)
        .where('Status', whereIn: ['Working'])
        .get();

    workingCarts = {};

    for (var doc in snapshot.docs) {
      var cartData = doc.data();
      String? ownerId = cartData['Owner'];
      String? assignedMechanicId = cartData['Mechanic'];

      // Debugging prints
      print("Cart ID: ${doc.id}, Owner ID: $ownerId, Assigned Mechanic ID: $assignedMechanicId");

      // Fetch owner details
      String? ownerName = ownerId != null ? await fetchUserName(ownerId) : "Unknown Owner";

      // Fetch mechanic details
      String? mechanicName = assignedMechanicId != null ? await fetchUserName(assignedMechanicId) : "Unknown Mechanic";

      // Debugging prints
      print("Cart ID: ${doc.id}, Mechanic Name: $mechanicName");

      workingCarts[doc.id] = {
        ...cartData,
        'OwnerName': ownerName,      // Store owner name
        'MechanicName': mechanicName // Store mechanic name
      };
    }

    print("Fetched working carts: $workingCarts");
    print("Exiting fetchWorkingCarts()");
  }

// Fetch user name from User collection
  Future<String?> fetchUserName(String userId) async {
    print("Entering fetchUserName() for User ID: $userId");
    var doc = await _firestore.collection('User').doc(userId).get();
    if (doc.exists) {
      String? name = doc.data()?['Name'];
      print("Fetched user name: $name");
      return name;
    }
    print("User ID: $userId not found.");
    print("Exiting fetchUserName()");
    return "Unknown User";
  }

  Future<void> fetchCartDetails(String cartId) async {
    print("Entering fetchCartDetails() for Cart ID: $cartId");
    var doc = await _firestore.collection('Cart').doc(cartId).get();

    if (doc.exists) {
      cartDetails = doc.data()!;
      if (cartDetails['Owner'] != null) {
        cartDetails['Customer'] = await fetchUserName(cartDetails['Owner']);
      }

      if (cartDetails['Mechanic'] != null) {
        cartDetails['MechanicName'] = await fetchUserName(cartDetails['Mechanic']);
      }
      print("Fetched cart details: $cartDetails");

      // ✅ Fetch product details (Name, Price) and use Cart's Quantity
      var productQuantities = (cartDetails['Products'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
      ) ?? {};

      cartDetails['Products'] = await fetchProductDetails(productQuantities);
      print("Fetched products: ${cartDetails['Products']}");

      // ✅ Fetch service details (Name, Price)
      var serviceIds = (cartDetails['Services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      cartDetails['Services'] = await fetchServiceDetails(serviceIds);
      print("Fetched services: ${cartDetails['Services']}");

      // ✅ Fetch user details
      if (cartDetails['Owner'] != null) {
        cartDetails['User'] = await fetchUserName(cartDetails['Owner']);
        cartDetails['Cart'] = cartId;
        print("Fetched user details: ${cartDetails['User']}");
      }
    } else {
      print("Cart ID: $cartId not found.");
    }

    print("Exiting fetchCartDetails()");
  }

  Future<Map<String, dynamic>> fetchProductDetails(Map<String, int> productQuantities) async {
    print("Entering fetchProductDetails()");

    // Ensure workshop ID is available before proceeding
    if (workedWorkshopId == null) {
      print("Workshop ID is null. Fetching worked workshop...");
      await fetchShiftWorkshop(_auth.currentUser?.uid ?? '');
    }

    // Double-check if it's still null after fetching
    if (workedWorkshopId == null || productQuantities.isEmpty) {
      print("Error: No workshop found or no products to fetch. Exiting fetchProductDetails().");
      return {};
    }

    Map<String, dynamic> products = {};

    // Fetch only required products from Firestore
    var snapshot = await _firestore
        .collection('Workshop')
        .doc(workedWorkshopId)
        .collection('Products')
        .where(FieldPath.documentId, whereIn: productQuantities.keys.toList())
        .get();

    for (var doc in snapshot.docs) {
      products[doc.id] = {
        'Name': doc.data()['Name'] ?? 'Unknown Product',
        'Price': doc.data()['Price'] ?? 0.0,
        'Quantity': productQuantities[doc.id] ?? 0 // ✅ Keep Quantity from Cart
      };
    }

    print("Fetched product details: $products");
    print("Exiting fetchProductDetails()");
    return products;
  }

  Future<Map<String, dynamic>> fetchServiceDetails(List<String> serviceIds) async {
    print("Entering fetchServiceDetails()");

    // Ensure workshop ID is available before proceeding
    if (workedWorkshopId == null) {
      print("Workshop ID is null. Fetching owned workshop...");
      await fetchShiftWorkshop(_auth.currentUser?.uid ?? '');
    }

    // Double-check if it's still null after fetching
    if (workedWorkshopId == null || serviceIds.isEmpty) {
      print("Error: No workshop found or no services to fetch. Exiting fetchServiceDetails().");
      return {};
    }

    Map<String, dynamic> services = {};

    // Fetch only needed services from Firestore
    var snapshot = await _firestore
        .collection('Workshop')
        .doc(workedWorkshopId)
        .collection('Services')
        .where(FieldPath.documentId, whereIn: serviceIds)
        .get();

    for (var doc in snapshot.docs) {
      services[doc.id] = {
        'Name': doc.data()['Name'] ?? 'Unknown Service',
        'Price': doc.data()['Price'] ?? 0.0
      };
    }

    print("Fetched service details: $services");
    print("Exiting fetchServiceDetails()");
    return services;
  }

  Future<void> updateStatus(String cartId, String action) async {
    print("Entering updateStatus() for Cart ID: $cartId with Action: $action");

    String newStatus = action == 'Start' ? 'Working' : 'Completed';

    await _firestore.collection('Cart').doc(cartId).update({
      'Status': newStatus,
    });

    print("Status updated to $newStatus.");
    print("Exiting updateStatus()");
  }

  Future<void> updateQuantity(
      String workshopId,
      String itemId,
      int change,
      Function setState,
      {bool isService = false, double price = 0.0}
      )
  async {
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
        DocumentSnapshot productSnapshot = await _firestore
            .collection('Workshop')
            .doc(workshopId)
            .collection('Products')
            .doc(itemId)
            .get();

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



}