import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:io';


class WorkController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> mechanicDetails = {};
  List<Map<String, dynamic>> mechanicShifts = [];
  double totalSalary = 0.0;
  bool isLoading = true;
  List<Map<String, dynamic>> filteredShifts = [];

  Future<void> initAssignData() async {
    print("Entering initAssignData()");
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      isLoading = true;
      await fetchMechanicDetails(userId);
      await fetchMechanicShiftsOptimized(userId);
      _prepareFilteredShifts();
      isLoading = false;
    }
    print("Exiting initAssignData()");
  }

  void _prepareFilteredShifts() {
    filteredShifts = mechanicShifts.map((shift) {
      String dateStr = shift['Date'];
      DateTime dateTime = DateTime.parse(dateStr);
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
      return {
        ...shift,
        'Formatted Date': formattedDate,
      };
    }).toList();
  }

  Future<void> fetchMechanicDetails(String userId) async {
    var doc = await _firestore.collection('User').doc(userId).get();
    if (doc.exists) {
      var data = doc.data() ?? {};
      mechanicDetails = {
        'Name': data['Name'] ?? 'Unknown',
        'Phone': data['Phone Number'] ?? '-',
        'Rating': (data['Rating'] ?? 0.0).toDouble(),
        'Rating Count': data.containsKey('Rating Count')
            ? data['Rating Count']
            : 0,
      };
    }
  }

  Future<void> fetchMechanicShiftsOptimized(String userId) async {
    mechanicShifts = [];
    totalSalary = 0.0;

    final workshopSnapshots = await _firestore.collection('Workshop').get();

    for (var workshopDoc in workshopSnapshots.docs) {
      String workshopId = workshopDoc.id;
      String workshopName = workshopDoc['Name'] ?? 'Unknown Workshop';

      final shiftsSnapshot = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .get();

      for (var shiftDoc in shiftsSnapshot.docs) {
        var applicants = shiftDoc['Applicant'] as List<dynamic>?;
        if (applicants != null) {
          for (var applicant in applicants) {
            if (applicant['id'] == userId &&
                ['Pending', 'Completed', 'Done'].contains(
                    applicant['Status'])) {
              double salary = (shiftDoc['Salary'] ?? 0.0).toDouble();
              String date = shiftDoc['Date'] ?? (Timestamp.now().toString());
              double rating = (shiftDoc['Rate'] ?? 0.0).toDouble();

              mechanicShifts.add({
                'Workshop Name': workshopName,
                'Salary': salary,
                'Status': applicant['Status'],
                'Rate': rating,
                'Date': date,
                'id': shiftDoc.id,
              });
              totalSalary += salary;
            }
          }
        }
      }
    }

    // Sort by latest date
    mechanicShifts.sort((a, b) =>
        DateTime.parse(b['Date']).compareTo(DateTime.parse(a['Date'])));
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      case 'Done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

// Updated fetchShiftDetails method
  Future<Map<String, dynamic>> fetchShiftDetails(String shiftId) async {
    try {
      final workshopSnapshots = await _firestore.collection('Workshop').get();

      for (var workshopDoc in workshopSnapshots.docs) {
        String workshopId = workshopDoc.id;
        String workshopName = workshopDoc['Name'] ?? 'Unknown Workshop';
        String contact = workshopDoc['Contact'] ?? 'Not Provided';
        String operating = workshopDoc['Operating Hours'] ?? 'Unknown';
        double workshopRating = workshopDoc['Rating'].toDouble() ?? '0.0';

        var shiftDoc = await _firestore
            .collection('Workshop')
            .doc(workshopId)
            .collection('Shifts')
            .doc(shiftId)
            .get();

        if (shiftDoc.exists) {
          var shiftData = shiftDoc.data() ?? {};

          // Find the current user's entry in the applicants list
          String userId = _auth.currentUser?.uid ?? '';
          final applicants = shiftData['Applicant'] ?? [];
          final userApplicant = (applicants as List).firstWhere(
                (app) => app['id'] == userId,
            orElse: () => {},
          );

          double salary = (shiftData['Salary'] ?? 0.0).toDouble();
          double rating = (shiftData['Rate'] ?? 0.0).toDouble();
          double workRate = (userApplicant["Workshop's Rate"] ?? 0.0).toDouble();
          double mechRate = (userApplicant["Mechanic's Rate"] ?? 0.0).toDouble();
          String date = shiftData['Date'] ?? '';
          String payDate = userApplicant['Payment Date'] ?? '';
          String status = userApplicant['Status'] ?? 'Unknown';
          // String mechanicName = userApplicant['id'] ?? '';
          String receiptId = userApplicant['Transaction ID'] ?? '';
          String start = shiftData['Start'] ?? 'Unknown';
          String end = shiftData['End'] ?? 'Unknown';

          // Fetch mechanic name properly from User collection
          String mechanicName = 'Unknown Mechanic';
          if (userApplicant.containsKey('id')) {
            var userDoc = await _firestore.collection('User').doc(userApplicant['id']).get();
            if (userDoc.exists) {
              mechanicName = userDoc.data()?['Name'] ?? mechanicName;
            }
          }

          print(start);
          return {
            'Workshop ID': workshopId,
            'Transaction ID': receiptId,
            'Workshop Name': workshopName,
            'Mechanic Name': mechanicName,
            'Rate': rating,
            'Rating': workshopRating,
            'Contact': contact,
            'Operating Hours': operating,
            "Workshop's Rate": workRate,
            "Mechanic's Rate": mechRate,
            'Salary': salary,
            'Status': status,
            'Date': date,
            'Payment Date': payDate,
            'Start': start,
            'End': end,
          };
        }
      }

      throw Exception('Shift not found in any workshop');
    } catch (e) {
      throw Exception('Error fetching shift details: $e');
    }
  }

  // To hold the selected rating from the slider (e.g., 1.0 to 5.0)
  double currentSliderValue = 3.0; // Default at 3 stars
  void updateSliderValue(double value) {
    currentSliderValue = value;
    print("Slider updated to: $currentSliderValue");
  }

  Future<void> rateWorkshop(String workshopId, String shiftId, double? customRating) async {
    print("Entering rateWorkshop");

    double finalRating = customRating ?? currentSliderValue;
    print("Final workshop rating to use: $finalRating");

    var docRef = _firestore.collection('Workshop').doc(workshopId);
    var doc = await docRef.get();

    if (doc.exists) {
      double currentRating = (doc.data()?['Rating'] ?? 0).toDouble();
      int ratingCount = (doc.data()?['Rating Count'] ?? 0);

      double updatedRating =
          ((currentRating * ratingCount) + finalRating) / (ratingCount + 1);

      await docRef.update({
        'Rating': double.parse(updatedRating.toStringAsFixed(2)),
        'Rating Count': ratingCount + 1,
      });

      String userId = _auth.currentUser?.uid ?? '';

      var shiftDocRef = _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId);

      var shiftDoc = await shiftDocRef.get();

      if (shiftDoc.exists) {
        var applicants = List<Map<String, dynamic>>.from(shiftDoc.data()?['Applicant'] ?? []);

        applicants = applicants.map((applicant) {
          if (applicant['id'] == userId) {
            double rated = (applicant["Mechanic's Rate"] ?? 0.0).toDouble();
            if (rated == 0.0){
              return {
                ...applicant,
                "Workshop's Rate": finalRating,
              };
            } else {
              return {
                ...applicant,
                'Status': 'Done',
                "Workshop's Rate": finalRating,
              };
            }
          }
          return applicant;
        }).toList();

        await shiftDocRef.update({'Applicant': applicants});
        print("Mechanic status updated to Done in shift.");
      }

      print("Workshop rated successfully. New rating: $updatedRating");

    } else {
      throw Exception('Workshop not found');
    }
  }

  Future<void> generateAndPrintReceipt(Map<String, dynamic> shift) async {
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

                _buildLabelValueText("Transaction Number", shift['Transaction ID']),
                _buildLabelValueText("Workshop", shift['Workshop Name']),
                _buildLabelValueText("Contact", shift['Contact']),
                _buildLabelValueText("Mechanic's Name", shift['Mechanic Name']),
                _buildLabelValueText("Date", shift['Date']),
                _buildLabelValueText("Shift Time", "${shift['Start']} - ${shift['End']}"),
                _buildLabelValueText("Hourly Rate", "RM${(shift['Rate'] ?? 0.0).toStringAsFixed(2)}"),
                _buildLabelValueText("Salary", "RM${(shift['Salary'] ?? 0.0).toStringAsFixed(2)}"),
                _buildLabelValueText("Payment Date", shift['Payment Date']),

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