import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to get the current user's workshop ID
  Future<String?> _getWorkshopId() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return null;
      }

      // Query for the workshop owned by the current user
      QuerySnapshot query = await _firestore
          .collection('Workshop')
          .where('Owner', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) {
        print('No workshop found for the current user');
        return null;
      }

      return query.docs.first.id; // Return the first workshop's ID
    } catch (e) {
      print('Error fetching workshop: $e');
      return null;
    }
  }

  // Fetch products for the user's workshop
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return [];

      QuerySnapshot query = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .get();

      return query.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the data
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

// Fetch services for the user's workshop
  Future<List<Map<String, dynamic>>> fetchServices() async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return [];

      QuerySnapshot query = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .get();

      return query.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the data
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Fetch shift for the user's workshop
  Future<List<Map<String, dynamic>>> fetchShifts() async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return [];

      QuerySnapshot query = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .get();

      return query.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching shifts: $e');
      return [];
    }
  }

  // Fetch a product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .doc(productId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      print('Product not found for ID: $productId');
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Fetch a service by ID
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .doc(serviceId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      print('Service not found for ID: $serviceId');
      return null;
    } catch (e) {
      print('Error fetching service: $e');
      return null;
    }
  }

  // Fetch a shift by ID
  Future<Map<String, dynamic>?> getShiftById(String shiftId) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      print('Shift not found for ID: $shiftId');
      return null;
    } catch (e) {
      print('Error fetching shift: $e');
      return null;
    }
  }

  // Add a new product to the user's workshop
  Future<void> addProduct(String name, String description, double price, int stock, bool isAvailable) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      // Adding the product
      DocumentReference docRef = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .add({
        'Name': name,
        'Description': description,
        'Price': price,
        'Stock': stock,
        'Availability': isAvailable,
        'Order': 0, // Initialize as 0
      });

      print('Product added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding product: $e');
    }
  }

// Add a new service to the user's workshop
  Future<void> addService(String name, String description, double price, bool isAvailable) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      // Adding the service
      DocumentReference docRef = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .add({
        'Name': name,
        'Description': description,
        'Price': price,
        'Availability': isAvailable,
      });

      print('Service added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding service: $e');
    }
  }

  // Add a new shift to the user's workshop
  Future<void> addShift(String day, String date, String startTime, String endTime, int totalVacancy, double rate, String jobScope) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) {
        print('Workshop ID not found.');
        return;
      }

      DocumentReference docRef = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .add({
        'Day': day,
        'Date': date,
        'Start': startTime,
        'End': endTime,
        'Rate': rate,
        'Vacancy': totalVacancy,
        'Applicant': [], // Default empty list
        'Availability': 'Available', // Default availability
        'Scope': jobScope,
      });

      print('Shift added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding shift: $e');
    }
  }

  // Update a product in the user's workshop
  Future<void> updateProduct(String productId, String name, String description, double price, int stock, bool isAvailable) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .doc(productId)
          .update({
        'Name': name,
        'Description': description,
        'Price': price,
        'Stock': stock,
        'Availability': isAvailable,
      });

      print('Product updated successfully');
    } catch (e) {
      print('Error updating product: $e');
    }
  }

  // Update a service in the user's workshop
  Future<void> updateService(String serviceId, String name, String description, double price, bool isAvailable) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .doc(serviceId)
          .update({
        'Name': name,
        'Description': description,
        'Price': price,
        'Availability': isAvailable,
      });

      print('Service updated successfully');
    } catch (e) {
      print('Error updating service: $e');
    }
  }

  // Update a shift in the user's workshop
  Future<void> updateShift(String shiftId, String day, String date, String startTime, String endTime, int totalVacancy, double rate, String jobScope) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId)
          .update({
        'Day': day,
        'Date': date,
        'Start': startTime,
        'End': endTime,
        'Vacancy': totalVacancy,
        'Rate': rate,
        'Scope': jobScope,
      });

      print('Shift updated successfully');
    } catch (e) {
      print('Error updating shift: $e');
    }
  }

  // Delete a product from the user's workshop
  Future<void> deleteProduct(String productId) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .doc(productId)
          .delete();

      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  // Delete a service from the user's workshop
  Future<void> deleteService(String serviceId) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .doc(serviceId)
          .delete();

      print('Service deleted successfully');
    } catch (e) {
      print('Error deleting service: $e');
    }
  }

  // Delete a shift from the user's workshop
  Future<void> deleteShift(String shiftId) async {
    try {
      String? workshopId = await _getWorkshopId();
      if (workshopId == null) return;

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId)
          .delete();

      print('Shift deleted successfully');
    } catch (e) {
      print('Error deleting shift: $e');
    }
  }
}
