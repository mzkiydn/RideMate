import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

          if (shiftDate == today && status == 'Accepted') {
            print("worker: $applicantId");

            todayAttendance[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          } else if (DateTime.parse(shiftDate).isAfter(now) && status == 'Applied') {
            upcomingAttendance[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          } else if (DateTime.parse(shiftDate).isBefore(now.add(Duration(days: 1))) && status == 'Pending') {
            pendingPayment[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          } else if (DateTime.parse(shiftDate).isBefore(now.add(Duration(days: 1))) && status == 'Completed') {
            completedPayment[applicantId] = await fetchMechanicDetails(workshopId, applicantId, shiftId);
          }
        }
      }
    }

    print("Today's Attendance: $todayAttendance");
    print("Upcoming Attendance: $upcomingAttendance");
    print("Pending Payments: $pendingPayment");
    print("Completed Payments: $completedPayment");
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

  // Pay the mechanic for the shift worked
  // missing Stripe
  Future<void> payMechanic(String workshopId, String shiftId, double amount) async {
    print("Entering payMechanic");

    try {
      var receipt = {
        'Amount': amount,
        'Date': Timestamp.now(),
        'Status': 'Completed'
      };

      await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Shifts')
          .doc(shiftId)
          .update({
        'Receipt': receipt,
        'Applicant': FieldValue.arrayUnion([{'Status': 'Completed'}])
      });

      print("Payment completed and receipt saved.");
    } catch (e) {
      print("Payment failed: $e");
    }
  }

  // To hold the selected rating from the slider (e.g., 1.0 to 5.0)
  double currentSliderValue = 3.0; // Default at 3 stars

  void updateSliderValue(double value) {
    currentSliderValue = value;
    print("Slider updated to: $currentSliderValue");
  }


  // Rate a mechanic based on their performance
// Rate a mechanic based on their performance
  Future<void> rateMechanic(String mechanicId, String workshopId, String shiftId, {double? customRating}) async {
    print("Entering rateMechanic");

    double finalRating = customRating ?? currentSliderValue; // use slider if no manual value
    print("Final rating to use: $finalRating");

    var docRef = _firestore.collection('User').doc(mechanicId);
    var doc = await docRef.get();

    if (doc.exists) {
      double currentRating = (doc.data()?['Rating'] ?? 0).toDouble();
      int ratingCount = (doc.data()?['RatingCount'] ?? 0);

      double updatedRating = ((currentRating * ratingCount) + finalRating) / (ratingCount + 1);

      await docRef.update({
        'Rating': double.parse(updatedRating.toStringAsFixed(2)),
        'RatingCount': ratingCount + 1,
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
            return {...applicant, 'Status': 'Done'};
          }
          return applicant;
        }).toList();

        await shiftDocRef.update({'Applicant': applicants});
        print("Mechanic status updated to Done in shift.");
      }
    }
  }


}
