import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class AssignController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> ownedWorkshops = []; // To store multiple workshops
  Map<String, dynamic> todayAttendance = {};
  Map<String, dynamic> upcomingAttendance = {};
  Map<String, dynamic> pendingPayment = {};
  Map<String, dynamic> completedPayment = {};

  // Initialize the controller and data
  Future<void> initAttendanceData() async {
    print("Initializing Attendance Data...");
    await fetchOwnedWorkshops();
    await fetchShiftsData();
    print("Finished Initializing Attendance Data.");
  }

  // Fetch workshops owned by the current user
  Future<void> fetchOwnedWorkshops() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    var snapshot = await _firestore
        .collection('Workshop')
        .where('Owner', isEqualTo: userId)
        .get();

    ownedWorkshops = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'Name': doc.data()['Name'] ?? 'Unknown Workshop',
      };
    }).toList();

    print("Fetched owned workshops: $ownedWorkshops");
  }

  // Fetch shift data for all owned workshops
  Future<void> fetchShiftsData() async {
    if (ownedWorkshops.isEmpty) return;

    DateTime now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    todayAttendance = {};
    upcomingAttendance = {};
    pendingPayment = {};
    completedPayment = {};

    for (var workshop in ownedWorkshops) {
      String workshopId = workshop['id'];

      var shiftSnapshot = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .get();

      // all shift
      for (var shiftDoc in shiftSnapshot.docs) {
        var shiftData = shiftDoc.data();

        String shiftDate = shiftData['Date'] ?? '';
        String shiftId = shiftDoc.id;

        List<dynamic> applicants = shiftData['Applicant'] ?? [];
        // all applicant for each shift
        for (var applicant in applicants) {
          String status = applicant['Status'] ?? '';
          String applicantId = applicant['id'] ?? '';
          double rated = (applicant["Mechanic's Rate"] ?? 0.0).toDouble();
          print("Checking shift: $shiftId, Date: $shiftDate, Applicants: $applicants");

          // If the applicant was accepted but did not attend and the shift date has passed
          if (status == 'Accepted' && DateTime.parse(shiftDate).isBefore(now)) {
            // Update status to 'Absent' in Firestore
            await markAsAbsent(workshopId, shiftId, applicantId);
            status = 'Absent'; // so it won't get processed in other categories
            continue; // Skip further processing for this applicant
          } else if (shiftDate == today && status == 'Check In') {
            todayAttendance[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          } else if ((shiftDate == today || DateTime.parse(shiftDate).isAfter(now)) && status == 'Applied') {
            upcomingAttendance[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          } else if (DateTime.parse(shiftDate).isBefore(now.add(Duration(days: 1))) && status == 'Pending') {
            pendingPayment[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          } else if (DateTime.parse(shiftDate).isBefore(now.add(Duration(days: 1))) && status == 'Completed') {
            if (rated == 0.0){
              completedPayment[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
            }
          }
        }
      }
    }

    print("Today's Attendance: $todayAttendance");
    print("Upcoming Attendance: $upcomingAttendance");
    print("Pending Payments: $pendingPayment");
    print("Completed Payments: $completedPayment");
  }

  // Update absent mechanic
  Future<void> markAsAbsent(String workshopId, String shiftId, String applicantId) async {
    var shiftDocRef = _firestore
        .collection('Workshop')
        .doc(workshopId)
        .collection('Shifts')
        .doc(shiftId);

    var shiftDoc = await shiftDocRef.get();

    if (shiftDoc.exists) {
      var applicants = List<Map<String, dynamic>>.from(shiftDoc.data()?['Applicant'] ?? []);

      applicants = applicants.map((applicant) {
        if (applicant['id'] == applicantId) {
          return {...applicant, 'Status': 'Absent'};
        }
        return applicant;
      }).toList();

      await shiftDocRef.update({'Applicant': applicants});
      print('Marked $applicantId as Absent for shift $shiftId');
    }
  }

  // Fetch mechanic details for a given applicant
  Future<Map<String, dynamic>> fetchMechanicDetails(String workshopId, String applicantId, String shiftId) async {
    var userDoc = await _firestore.collection('User').doc(applicantId).get();
    if (!userDoc.exists) return {'Name': 'Unknown', 'Phone Number': '-', 'Rating': 0.0, 'Start': 'N/A', 'End': 'N/A'};

    var data = userDoc.data()!;
    var shiftDoc = await _firestore
        .collection('Workshop')
        .doc(workshopId)
        .collection('Shifts')
        .doc(shiftId)
        .get();

    var shiftData = shiftDoc.data();
    String start = shiftData?['Start'] ?? 'N/A';
    String end = shiftData?['End'] ?? 'N/A';
    double rate = shiftData?['Rate'] ?? 0.0;
    double salary = shiftData?['Salary'] ?? 0.00;

    return {
      'Name': data['Name'] ?? 'Unknown',
      'Phone Number': data['Phone Number'] ?? '-',
      'Rating': data['Rating'] ?? 0.0,
      'Start': start,
      'End': end,
      'Workshop ID': workshopId,
      'Applicant ID': applicantId,
      'Shift ID': shiftId,
      'Rate': rate,
      'Salary': salary,
    };
  }

  // Verify attendance and calculate the salary for a mechanic
  Future<void> verifyAttendance(String workshopId, String shiftId, String applicantId, double rate) async {
    print("Entering verifyAttendance");

    if (workshopId.isEmpty || shiftId.isEmpty || applicantId.isEmpty || rate == 0) {
      print("Missing required data for verification");
      return;
    }

    try {
      var shiftDoc = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId)
          .get();

      if (shiftDoc.exists) {
        var data = shiftDoc.data();
        String startString = data?['Start'] ?? '';
        String endString = data?['End'] ?? '';

        DateTime? start = _parseTimeString(startString);
        DateTime? end = _parseTimeString(endString);

        if (start == null || end == null) {
          print("Invalid start or end time format");
          return;
        }

        double workingHours = end.difference(start).inMinutes / 60;
        double salary = double.parse((workingHours * rate).toStringAsFixed(2));

        // Fetch current applicant data
        List<dynamic> applicants = List<Map<String, dynamic>>.from(data?['Applicant'] ?? []);

        // Update the applicant's status and salary in the list
        applicants = applicants.map((applicant) {
          if (applicant['id'] == applicantId) {
            return {
              ...applicant,
              'Status': 'Pending',  // Update status
            };
          }
          return applicant;
        }).toList();

        // Save the updated applicant list to Firestore
        await _firestore
            .collection('Workshop')
            .doc(workshopId)
            .collection('Shifts')
            .doc(shiftId)
            .update({
          'Salary': salary,
          'Applicant': applicants,  // Replace with the updated applicants list
        });

        print("Attendance verified and salary set: $salary");
      }
    } catch (e) {
      print("Error in verifyAttendance: $e");
    }
  }

  // Approve an applicant for a specific shift
  Future<void> approveApplicant(String workshopId, String shiftId, String applicantId) async {
    print("Entering approveApplicant");

    var shiftDocRef = _firestore
        .collection('Workshop')
        .doc(workshopId)
        .collection('Shifts')
        .doc(shiftId);

    var shiftDoc = await shiftDocRef.get();

    if (shiftDoc.exists) {
      var applicants = List<Map<String, dynamic>>.from(shiftDoc.data()?['Applicant'] ?? []);
      applicants = applicants.map((applicant) {
        if (applicant['id'] == applicantId) {
          return {...applicant, 'Status': 'Accepted'};
        }
        return applicant;
      }).toList();

      await shiftDocRef.update({'Applicant': applicants});
      print("Applicant approved successfully.");
    }
  }

  Future<void> updateApplicantStatus(String workshopId, String shiftId, String applicantId, String comment) async {
    print("Updating status for applicant $applicantId");

    var shiftDocRef = _firestore
        .collection('Workshop')
        .doc(workshopId)
        .collection('Shifts')
        .doc(shiftId);

    var shiftDoc = await shiftDocRef.get();

    if (shiftDoc.exists) {
      var applicants = List<Map<String, dynamic>>.from(shiftDoc.data()?['Applicant'] ?? []);

      applicants = applicants.map((applicant) {
        if (applicant['id'] == applicantId) {
          return {...applicant, 'Status': 'Rejected', 'Comment': comment};
        }
        return applicant;
      }).toList();

      int updatedVacancy = (shiftDoc.data()!['Vacancy'] as int) + 1;
      String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

      await shiftDocRef.update({
        'Applicant': applicants,
        'Vacancy': updatedVacancy,
        'Availability': availabilityStatus,
      });

    }
  }

  // Parse a time string into a DateTime object
  DateTime? _parseTimeString(String timeString) {
    try {
      DateFormat format = DateFormat("hh:mm a");
      return format.parse(timeString);
    } catch (e) {
      print("Error parsing time string: $timeString, error: $e");
      return null;
    }
  }

  // Call a mechanic using their phone number
  // missing calling function
  Future<void> callMechanic(String phoneNumber) async {
    print("Calling mechanic at: $phoneNumber");
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    // Open the phone dialer if needed (implementing platform-specific functionality)
  }

  // // Pay the mechanic for the shift worked
  // Future<void> payMechanic({required BuildContext context, required double amount, required String applicantId, required String shiftId, required String workshopId}) async {
  //   final Dio dio = Dio();
  //   try {
  //     print('inside');
  //     final int centAmount = (amount * 100).toInt();
  //
  //     final response = await dio.post(
  //       'http://10.0.2.2:5000/create-payment-intent',
  //       data: {
  //         'amount': centAmount,
  //         'applicantId': applicantId,
  //         'shiftId': shiftId,
  //         'workshopId': workshopId,
  //       },
  //       options: Options(headers: {'Content-Type': 'application/json'}),
  //     );
  //
  //     print('inside 1');
  //
  //     final data = response.data;
  //     final clientSecret = data['clientSecret'];
  //     if (clientSecret == null) throw Exception('Missing client secret');
  //
  //     const platform = MethodChannel('com.ridemate.ridemate/payment');
  //
  //     print('inside 2');
  //
  //     final result = await platform.invokeMethod('startStripeActivity', {
  //       'amount': amount,
  //       'shiftId': shiftId,
  //       'workshopId': workshopId,
  //       'applicantId': applicantId,
  //     });
  //
  //     if (result == 'launched') {
  //       print('StripeActivity launched successfully');
  //     }
  //
  //     print('this is $result');
  //
  //
  //     print('inside 3');
  //
  //     if (result == 'success') {
  //       print('inside 4');
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Payment successful')),
  //       );
  //     } else {
  //       print('inside 5');
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Payment failed')),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error during payment: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Payment failed: $e')),
  //     );
  //   }
  //   print('inside 6');
  //
  // }
  //
  // Future<Map<String, dynamic>?> createPaymentIntent(String amount, String currency) async {
  //   try {
  //     final body = {
  //       'amount': amount,
  //       'currency': currency,
  //       'payment_method_types[]': 'card',
  //     };
  //
  //     final Dio dio = Dio();
  //
  //     final response = await dio.post(
  //       'https://api.stripe.com/v1/payment_intents',
  //       data: body,
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer SecretKey', // Replace with secret key
  //           'Content-Type': 'application/x-www-form-urlencoded'
  //         },
  //       ),
  //     );
  //
  //     return response.data;
  //   } catch (err) {
  //     print('Error creating payment intent: $err');
  //     return null;
  //   }
  // }
  //
  // Future<void> makePayment({required String amount, required String currency}) async {
  //   try {
  //     var paymentIntent = await createPaymentIntent(amount, currency);
  //     if (paymentIntent == null) return;
  //
  //     // await Stripe.instance.initPaymentSheet(
  //     //   paymentSheetParameters: SetupPaymentSheetParameters(
  //     //     paymentIntentClientSecret: paymentIntent['client_secret'],
  //     //     style: ThemeMode.light,
  //     //     merchantDisplayName: 'RideMate',
  //     //   ),
  //     // );
  //
  //     await displayPaymentSheet();
  //
  //   } catch (e) {
  //     print('Payment failed: $e');
  //   }
  // }
  //
  // Future<void> displayPaymentSheet() async {
  //   try {
  //     // await Stripe.instance.presentPaymentSheet();
  //     print("Success: Payment completed!");
  //   } catch (e) {
  //     // if (e is StripeException) {
  //     //   print("Payment Cancelled: ${e.error.message ?? 'Unknown error'}");
  //     // } else {
  //     //   print("Unexpected error: $e");
  //     // }
  //   }
  // }
  //
  // To hold the selected rating from the slider (e.g., 1.0 to 5.0)

  Future<void> completePayment(String workshopId, String shiftId, String applicantId) async {
    var shiftDocRef = _firestore
        .collection('Workshop')
        .doc(workshopId)
        .collection('Shifts')
        .doc(shiftId);

    var shiftDoc = await shiftDocRef.get();

    if (shiftDoc.exists) {
      var applicants = List<Map<String, dynamic>>.from(shiftDoc.data()?['Applicant'] ?? []);

      final now = DateTime.now();

      applicants = applicants.map((applicant) {
        if (applicant['id'] == applicantId) {
          return {
            ...applicant,
            'Status': 'Completed',
            'Transaction ID': 'RDM-${now.millisecondsSinceEpoch}',
            'Payment Date': now.toIso8601String(),
          };
        }
        return applicant;
      }).toList();

      await shiftDocRef.update({'Applicant': applicants});
      print('Marked $applicantId as Completed for shift $shiftId');
    }
  }

  double currentSliderValue = 3.0; // Default at 3 stars
  void updateSliderValue(double value) {
    currentSliderValue = value;
    print("Slider updated to: $currentSliderValue");
  }

  // Rate a mechanic based on their performance
  Future<void> rateMechanic(String mechanicId, String workshopId, String shiftId, {double? customRating}) async {
    print("Entering rateMechanic");

    double finalRating = customRating ?? currentSliderValue; // use slider if no manual value
    print("Final rating to use: $finalRating");

    var docRef = _firestore.collection('User').doc(mechanicId);
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

      print("Mechanic rated successfully. New rating: $updatedRating");

      // Now update applicant status to 'Done'
      var shiftDocRef = _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId);

      var shiftDoc = await shiftDocRef.get();

      if (shiftDoc.exists) {
        var applicants = List<Map<String, dynamic>>.from(shiftDoc.data()?['Applicant'] ?? []);

        applicants = applicants.map((applicant) {
          if (applicant['id'] == mechanicId) {
            double rated = (applicant["Workshop's Rate"] ?? 0.0).toDouble();
            if(rated == 0.0){
              return {
                ...applicant,
                "Mechanic's Rate": finalRating,
              };
            } else {
              return {
                ...applicant,
                'Status': 'Done',
                "Mechanic's Rate": finalRating,
              };
            }
          }
          return applicant;
        }).toList();

        await shiftDocRef.update({'Applicant': applicants});
        print("Mechanic status updated to Done in shift.");
      }
    }
  }




}
