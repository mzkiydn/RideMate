import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

              mechanicShifts.add({
                'Workshop Name': workshopName,
                'Salary': salary,
                'Status': applicant['Status'],
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
          double rating = (shiftData['Rating'] ?? 0.0).toDouble();
          double workRate = (userApplicant["Workshop's Rate"] ?? 0.0).toDouble();
          String date = shiftData['Date'] ?? '';
          String status = userApplicant['Status'] ?? 'Unknown';
          String start = shiftData['Start'] ?? 'Unknown';
          String end = shiftData['End'] ?? 'Unknown';

          print(start);
          return {
            'Workshop ID': workshopId,
            'Workshop Name': workshopName,
            'Rate': rating,
            'Contact': contact,
            'Operating Hours': operating,
            "Workshop's Rate": workRate,
            'Salary': salary,
            'Status': status,
            'Date': date,
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

    double finalRating = customRating ?? 0.0; // Replace with slider value if needed
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

      // Store mechanic's rating for this shift
      // var shiftDocRef = _firestore
      //     .collection('Workshop')
      //     .doc(workshopId)
      //     .collection('Shifts')
      //     .doc(shiftId);
      //
      // var shiftDoc = await shiftDocRef.get();
      //
      // if (shiftDoc.exists) {
      //   await shiftDocRef.update({'RatedByMechanic': finalRating});
      //   print("Workshop rating stored in shift.");
      // }
    } else {
      throw Exception('Workshop not found');
    }
  }

}