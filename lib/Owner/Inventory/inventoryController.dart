import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  Future<void> addProduct(String name, String description, double price, int stock, bool isAvailable, String? motorcycle) async {
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
        'Motorcycle': motorcycle,
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
  Future<void> updateProduct(String productId, String name, String description, double price, int stock, bool isAvailable, String? motorcycle) async {
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
        'Motorcycle': motorcycle,
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

  Future<Map<String, dynamic>> fetchShiftDetails(String shiftId) async {
    try {
      final workshopSnapshots = await _firestore.collection('Workshop').get();

      for (var workshopDoc in workshopSnapshots.docs) {
        String workshopId = workshopDoc.id;
        String workshopName = workshopDoc['Name'] ?? 'Unknown Workshop';
        String contact = workshopDoc['Contact'] ?? 'Not Provided';
        String operating = workshopDoc['Operating Hours'] ?? 'Unknown';
        double workshopRating = (workshopDoc['Rating'] ?? 0.0).toDouble();
        double mechanicRate;

        var shiftDoc = await _firestore
            .collection('Workshop')
            .doc(workshopId)
            .collection('Shifts')
            .doc(shiftId)
            .get();

        if (shiftDoc.exists) {
          var shiftData = shiftDoc.data() ?? {};

          String start = shiftData['Start'] ?? 'Unknown';
          String end = shiftData['End'] ?? 'Unknown';
          String date = shiftData['Date'] ?? '';
          double rate = (shiftData['Rate'] ?? 0.0).toDouble();
          double salary = (shiftData['Salary'] ?? 0.0).toDouble();
          int vacancy = (shiftData['Vacancy'] ?? 0);

          // Get all applicants
          List<dynamic> applicantsRaw = shiftData['Applicant'] ?? [];

          // Prepare list of applicants with details
          List<Map<String, dynamic>> applicants = [];

          for (var app in applicantsRaw) {
            // Get mechanic name from User collection
            String mechanicName = 'Unknown Mechanic';
            if (app.containsKey('id')) {
              var userDoc = await _firestore.collection('User').doc(app['id']).get();
              if (userDoc.exists) {
                mechanicName = userDoc.data()?['Name'] ?? mechanicName;
              }
            }

            applicants.add({
              'Mechanic ID': app['id'], // Add this line
              'Mechanic Name': mechanicName,
              'Salary': (app['Salary'] ?? salary).toDouble(),
              "Workshop's Rate": (app["Workshop's Rate"] ?? workshopRating).toDouble(),
              "Mechanic's Rate": (app["Mechanic's Rate"] ?? 0.0).toDouble(),
              'Status': app['Status'] ?? 'Unknown',
              'Transaction ID': app['Transaction ID'] ?? 'Unknown',
              'Payment Date': app['Payment Date'] ?? 'Unknown',
            });

          }

          return {
            'Workshop ID': workshopId,
            'Workshop Name': workshopName,
            'Contact': contact,
            'Operating Hours': operating,
            'Rating': workshopRating,
            'Start': start,
            'End': end,
            'Date': date,
            'Rate': rate,
            'Salary': salary,
            'Vacancy': vacancy,
            'Applicants': applicants,
          };
        }
      }

      throw Exception('Shift not found in any workshop');
    } catch (e) {
      throw Exception('Error fetching shift details: $e');
    }
  }

  Future<void> generateAndPrintReceipt(Map<String, dynamic> shift, String mechanicId) async {
    // Extract the correct applicant from the Applicants list
    final applicants = shift['Applicants'] as List<dynamic>? ?? [];

    final applicant = applicants.firstWhere(
          (app) => app['Mechanic ID'] == mechanicId,
      orElse: () => <String, dynamic>{}, // return empty map instead of null
    );


    if (applicant == null) {
      throw Exception("Mechanic's data not found for receipt.");
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "RideMate Shift Receipt",
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 32),

                _buildLabelValueText("Transaction Number", applicant['Transaction ID']),
                _buildLabelValueText("Workshop", shift['Workshop Name']),
                _buildLabelValueText("Contact", shift['Contact']),
                _buildLabelValueText("Mechanic's Name", applicant['Mechanic Name']),
                _buildLabelValueText("Date", shift['Date']),
                _buildLabelValueText("Shift Time", "${shift['Start']} - ${shift['End']}"),
                _buildLabelValueText("Hourly Rate", "RM${(shift['Rate'] ?? 0.0).toStringAsFixed(2)}"),
                _buildLabelValueText("Salary", "RM${(applicant['Salary'] ?? 0.0).toStringAsFixed(2)}"),
                _buildLabelValueText("Payment Date", applicant['Payment Date']),

                pw.SizedBox(height: 40),
                pw.Divider(),

                pw.SizedBox(height: 16),
                pw.Text(
                  "Thank you for your hard work!",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Helper method to build label-value row for PDF
  pw.Widget _buildLabelValueText(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              value?.toString() ?? '-',
              style: pw.TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

}
