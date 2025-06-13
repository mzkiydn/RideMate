import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class ShiftController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // fetch all shift
  Future<List<Map<String, dynamic>>> fetchShifts(String status) async {
    return await _fetchShiftsByStatus(status);
  }

  // fetch current week date
  Future<List<Map<String, dynamic>>> fetchCurrentShifts() async {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime sunday = monday.add(Duration(days: 6));
    String startOfWeek = DateFormat('yyyy-MM-dd').format(monday);
    String endOfWeek = DateFormat('yyyy-MM-dd').format(sunday);
    print("current");
    return await _fetchShiftsByApplicantStatus(startOfWeek, endOfWeek);
  }

  // fetch the upcoming week
  Future<List<Map<String, dynamic>>> fetchUpcomingShifts() async {
    DateTime now = DateTime.now();
    DateTime nextMonday = now.add(Duration(days: 8 - now.weekday));
    DateTime nextSunday = nextMonday.add(Duration(days: 6));
    String startOfNextWeek = DateFormat('yyyy-MM-dd').format(nextMonday);
    String endOfNextWeek = DateFormat('yyyy-MM-dd').format(nextSunday);
    print("upcoming");
    return await _fetchShiftsByApplicantStatus(startOfNextWeek, endOfNextWeek);
  }

  // fetch shift with available vacancy
  Future<List<Map<String, dynamic>>> _fetchShiftsByStatus(String status) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      QuerySnapshot workshopQuery = await _firestore.collection('Workshop').get();
      List<Map<String, dynamic>> shifts = [];

      for (var workshop in workshopQuery.docs) {
        Map<String, dynamic> workshopData = await fetchWorkshopData(workshop.id);

        QuerySnapshot shiftQuery = await _firestore
            .collection('Workshop')
            .doc(workshop.id)
            .collection('Shifts')
            .get();

        List<QueryDocumentSnapshot> filteredShiftDocs = [];

        for (var doc in shiftQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> applicants = data['Applicant'] ?? [];

          DateTime today = DateTime.now();
          DateTime shiftDate = DateFormat('yyyy-MM-dd').parse(data['Date']);
          final shiftRef = _firestore
              .collection('Workshop')
              .doc(workshop.id)
              .collection('Shifts')
              .doc(doc.id);

          // Automatically mark past shifts as Full if not already
          if (shiftDate.isBefore(DateTime(today.year, today.month, today.day))) {
            if (data['Availability'] != 'Full') {
              await shiftRef.update({'Availability': 'Full'});
              data['Availability'] = 'Full';
            }
          }

          if (status == 'Dropped') {
            bool isDropped = applicants.any((app) =>
            app['id'] == currentUserId && app['Status'] == 'Dropped');
            if (isDropped) filteredShiftDocs.add(doc);
          } else {
            bool isAvailable = data['Availability'] == status;
            bool alreadyApplied = applicants.any((app) => app['id'] == currentUserId);
            if (isAvailable && !alreadyApplied) {
              filteredShiftDocs.add(doc);
            }
          }
        }

        shifts.addAll(_mapShifts(filteredShiftDocs, workshop.id, workshopData));
      }

      return shifts;
    } catch (e) {
      print('Error fetching shifts: $e');
      return [];
    }
  }

  // fetch shift with specific week and applicant status for specific applicant
  Future<List<Map<String, dynamic>>> _fetchShiftsByApplicantStatus([String? startDate, String? endDate]) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      DateTime? start = startDate != null ? DateFormat('yyyy-MM-dd').parse(startDate) : null;
      DateTime? end = endDate != null ? DateFormat('yyyy-MM-dd').parse(endDate) : null;
      DateTime today = DateTime.now();
      DateTime cutoffDate = DateTime.utc(today.year, today.month, today.day);

      List<Map<String, dynamic>> shifts = [];

      for (DateTime? currentDay = start;
      currentDay!.isBefore(end!.add(Duration(days: 1)));
      currentDay = currentDay.add(Duration(days: 1))) {
        String currentDayStr = DateFormat('yyyy-MM-dd').format(currentDay);

        QuerySnapshot workshopQuery = await _firestore.collection('Workshop').get();

        for (var workshop in workshopQuery.docs) {
          Map<String, dynamic> workshopData = await fetchWorkshopData(workshop.id);

          QuerySnapshot shiftQuery = await _firestore
              .collection('Workshop')
              .doc(workshop.id)
              .collection('Shifts')
              .where('Date', isEqualTo: currentDayStr)
              .get();

          for (var shiftDoc in shiftQuery.docs) {
            var data = shiftDoc.data() as Map<String, dynamic>;
            List<dynamic> applicants = data['Applicant'] ?? [];
            bool modified = false;

            for (int i = 0; i < applicants.length; i++) {
              if (applicants[i]['id'] == currentUserId) {
                String status = applicants[i]['Status'];
                DateTime shiftDate = DateFormat('yyyy-MM-dd').parse(data['Date']);
                shiftDate = DateTime.utc(shiftDate.year, shiftDate.month, shiftDate.day);

                if (shiftDate.isBefore(cutoffDate)) {
                  if (status == 'Accepted') {
                    applicants[i]['Status'] = 'Absent';
                    modified = true;
                  } else if (status == 'Applied') {
                    applicants[i]['Status'] = 'Rejected';
                    modified = true;
                  }
                }
              }
            }

            if (modified) {
              await _firestore
                  .collection('Workshop')
                  .doc(workshop.id)
                  .collection('Shifts')
                  .doc(shiftDoc.id)
                  .update({'Applicant': applicants});
            }

            // After modification, re-check if the current user has the shift (still accepted/applied/absent)
            var updatedApplicant = applicants.firstWhere(
                  (a) => a['id'] == currentUserId &&
                  ['Accepted', 'Applied', 'Absent'].contains(a['Status']),
              orElse: () => null,
            );

            if (updatedApplicant != null) {
              Map<String, dynamic> shiftWithMeta = {
                ...data,
                'id': shiftDoc.id,
                'workshopId': workshop.id,
                'workshopData': workshopData,
                'ApplicantStatus': updatedApplicant['Status'],
              };
              shifts.add(shiftWithMeta);
            }
          }
        }
      }

      return shifts;
    } catch (e) {
      print('Error fetching shifts by applicant status: $e');
      return [];
    }
  }

  // fetch workshop detail
  Future<Map<String, dynamic>> fetchWorkshopData(String workshopId) async {
    try {
      DocumentSnapshot workshopDoc = await _firestore.collection('Workshop').doc(workshopId).get();
      return workshopDoc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('Error fetching workshop data: $e');
      return {};
    }
  }

  // mapping workshop data into variable
  List<Map<String, dynamic>> _mapShifts(List<QueryDocumentSnapshot> shiftDocs, String workshopId, Map<String, dynamic> workshopData) {
    return shiftDocs.map((shift) {
      Map<String, dynamic> shiftData = shift.data() as Map<String, dynamic>;
      shiftData['workshopData'] = workshopData;
      shiftData['id'] = shift.id;
      shiftData['workshopId'] = workshopId;
      shiftData['Name'] = workshopData['Name'] ?? 'Unknown';
      shiftData['Address'] = workshopData['Address'] ?? 'Not provided';
      shiftData['Contact'] = workshopData['Contact'] ?? 'No contact';
      shiftData['Latitude'] = workshopData['Latitude'] ?? '';
      shiftData['Longitude'] = workshopData['Longitude'] ?? '';
      return shiftData;
    }).toList();
  }

  // get shift by id
  Future<Map<String, dynamic>?> fetchShiftById(String shiftId) async {
    try {
      QuerySnapshot workshopQuery = await _firestore.collection('Workshop').get();

      for (var workshop in workshopQuery.docs) {
        DocumentSnapshot shiftDoc = await _firestore
            .collection('Workshop')
            .doc(workshop.id)
            .collection('Shifts')
            .doc(shiftId)
            .get();

        if (shiftDoc.exists) {
          Map<String, dynamic> shiftData = shiftDoc.data() as Map<String, dynamic>;
          shiftData['id'] = shiftId;
          shiftData['workshopId'] = workshop.id;

          // Fetch workshop details
          Map<String, dynamic> workshopData = await fetchWorkshopData(workshop.id);
          shiftData['Name'] = workshopData['Name'] ?? 'Unknown';
          shiftData['Address'] = workshopData['Address'] ?? 'Not provided';
          shiftData['Contact'] = workshopData['Contact'] ?? 'No contact';
          shiftData['Latitude'] = workshopData['Latitude'] ?? '';
          shiftData['Longitude'] = workshopData['Longitude'] ?? '';

          return shiftData;
        }
      }
      return null; // Shift not found in any workshop
    } catch (e) {
      print('Error fetching shift details: $e');
      return null;
    }
  }

  // Apply for a shift
  Future<void> applyForShift(Map<String, dynamic> shiftDetails, String shiftId, {BuildContext? context}) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (shiftDetails == null || currentUserId == null) return;

    try {
      final newDate = shiftDetails['Date'];
      final newStart = _parseTime(shiftDetails['Start']);
      final newEnd = _parseTime(shiftDetails['End']);

      // 1. Check for time clash
      final workshopQuery = await _firestore.collection('Workshop').get();
      for (var workshop in workshopQuery.docs) {
        final shiftsSnapshot = await _firestore
            .collection('Workshop')
            .doc(workshop.id)
            .collection('Shifts')
            .get();

        for (var shiftDoc in shiftsSnapshot.docs) {
          final data = shiftDoc.data();
          final workshopData = await fetchWorkshopData(workshop.id);
          final applicants = List.from(data['Applicant'] ?? []);
          final isUserApplied = applicants.any((app) =>
          app['id'] == currentUserId &&
              (app['Status'] == 'Applied' || app['Status'] == 'Accepted'));

          if (!isUserApplied || data['Date'] != newDate) continue;

          final existingStart = _parseTime(data['Start']);
          final existingEnd = _parseTime(data['End']);

          if (_isTimeOverlap(newStart, newEnd, existingStart, existingEnd)) {
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shift clash with ${workshopData['Name'] ?? 'another workshop'} on $newDate',
                  ),
                  // backgroundColor: Colors.red,
                ),
              );
            }
            return; // Abort apply
          }
        }
      }

      // 2. Proceed with original apply logic
      final shiftRef = _firestore
          .collection('Workshop')
          .doc(shiftDetails['workshopId'])
          .collection('Shifts')
          .doc(shiftId);

      List<dynamic> applicants = List.from(shiftDetails['Applicant'] ?? []);
      int droppedIndex = applicants.indexWhere((app) => app['Status'] == 'Dropped');

      DocumentSnapshot userSnapshot = await _firestore.collection('User').doc(currentUserId).get();
      double? rating;
      if (userSnapshot.exists) {
        var data = userSnapshot.data() as Map<String, dynamic>;
        rating = (data['Rating'] != null) ? (data['Rating'] as num).toDouble() : null;
      }

      String applicantStatus = (rating != null && rating > 2.0) ? 'Accepted' : 'Applied';

      int updatedVacancy = (shiftDetails['Vacancy'] as int) - 1;
      String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

      if (droppedIndex != -1) {
        applicants[droppedIndex] = {
          'id': currentUserId,
          'Status': applicantStatus,
        };

        await shiftRef.update({
          'Applicant': applicants,
          'Vacancy': updatedVacancy,
          'Availability': availabilityStatus,
        });
      } else {
        await shiftRef.update({
          'Applicant': FieldValue.arrayUnion([
            {'id': currentUserId, 'Status': applicantStatus}
          ]),
          'Vacancy': updatedVacancy,
          'Availability': availabilityStatus,
        });
      }
    } catch (e) {
      print('Error applying for shift: $e');
    }
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  bool _isTimeOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  // Drop a shift
  Future<void> dropShift(Map<String, dynamic> shiftDetails, String shiftId) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (shiftDetails == null || currentUserId == null) return;

    try {
      final shiftRef = FirebaseFirestore.instance
          .collection('Workshop')
          .doc(shiftDetails['workshopId'])
          .collection('Shifts')
          .doc(shiftId);

      List<dynamic> updatedApplicants = List.from(shiftDetails['Applicant'] ?? []);

      for (var applicant in updatedApplicants) {
        if (applicant['id'] == currentUserId) {
          applicant['Status'] = 'Dropped';
          break;
        }
      }

      int updatedVacancy = (shiftDetails['Vacancy'] as int) + 1;
      String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

      await shiftRef.update({
        'Applicant': updatedApplicants,
        'Vacancy': updatedVacancy,
        'Availability': availabilityStatus,
      });
    } catch (e) {
      print("Error dropping shift: $e");
    }
  }

  // get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permission denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permission permanently denied.");
        return null;
      }

      Position position = await Geolocator.getCurrentPosition();
      print("Current user location: (${position.latitude}, ${position.longitude})");
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // Check-in to a shift
  Future<void> checkIn(BuildContext context, Map<String, dynamic> shiftDetails, String shiftId) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (shiftDetails == null || currentUserId == null) return;

    try {
      // Get current user location
      LatLng? userLocation = await getCurrentLocation();
      if (userLocation == null) {
        print("Unable to determine user location.");
        return;
      }

      // Get workshop location
      double workshopLat = shiftDetails['Latitude'];
      double workshopLng = shiftDetails['Longitude'];
      LatLng workshopLocation = LatLng(workshopLat, workshopLng);

      // Calculate distance
      final Distance distance = Distance();
      double km = distance.as(LengthUnit.Kilometer, userLocation, workshopLocation);

      if (km > 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You must be within 1km to check in. Current distance: ${km.toStringAsFixed(2)} km."),
            backgroundColor: Colors.blueGrey,
          ),
        );
        return;
      }

      // Proceed with check-in
      final shiftRef = FirebaseFirestore.instance
          .collection('Workshop')
          .doc(shiftDetails['workshopId'])
          .collection('Shifts')
          .doc(shiftId);

      List<dynamic> updatedApplicants = List.from(shiftDetails['Applicant'] ?? []);
      for (var applicant in updatedApplicants) {
        if (applicant['id'] == currentUserId) {
          applicant['Status'] = 'Check In';
          break;
        }
      }

      await shiftRef.update({
        'Applicant': updatedApplicants,
      });

    } catch (e) {
      print("Error checking in shift: $e");
    }
  }

}