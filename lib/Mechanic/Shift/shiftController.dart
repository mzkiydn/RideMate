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

        // Always fetch all shifts regardless of 'Dropped' status
        QuerySnapshot shiftQuery = await _firestore
            .collection('Workshop')
            .doc(workshop.id)
            .collection('Shifts')
            .get();

        List<QueryDocumentSnapshot> filteredShiftDocs;

        if (status == 'Dropped') {
          filteredShiftDocs = shiftQuery.docs.where((doc) {
            final List<dynamic> applicants = doc['Applicant'] ?? [];
            return applicants.any((app) =>
            app['id'] == currentUserId && app['Status'] == 'Dropped');
          }).toList();
          print('Filtered dropped shifts: ${filteredShiftDocs.length}');
        } else {
          filteredShiftDocs = shiftQuery.docs.where((doc) {
            final String availability = doc['Availability'] ?? '';
            final List<dynamic> applicants = doc['Applicant'] ?? [];
            return availability == status &&
                !applicants.any((app) => app['id'] == currentUserId);
          }).toList();
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
                if (shiftDate.isBefore(today)) {
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
  Future<void> applyForShift(Map<String, dynamic> shiftDetails, String shiftId) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (shiftDetails == null || currentUserId == null) return;

    try {
      final shiftRef = FirebaseFirestore.instance
          .collection('Workshop')
          .doc(shiftDetails['workshopId'])
          .collection('Shifts')
          .doc(shiftId);

      List<dynamic> applicants = List.from(shiftDetails['Applicant'] ?? []);
      int droppedIndex = applicants.indexWhere((app) => app['Status'] == 'Dropped');

      // Fetch current user's rating
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUserId)
          .get();

      double? rating;
      if (userSnapshot.exists) {
        var data = userSnapshot.data() as Map<String, dynamic>;
        rating = (data['Rating'] != null) ? (data['Rating'] as num).toDouble() : null;
      }

      String applicantStatus = (rating != null && rating > 2.0) ? 'Accepted' : 'Applied';

      if (droppedIndex != -1) {
        // Replace dropped applicant with current user
        applicants[droppedIndex] = {
          'id': currentUserId,
          'Status': applicantStatus,
        };

        int updatedVacancy = (shiftDetails['Vacancy'] as int) - 1;
        String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

        await shiftRef.update({
          'Applicant': applicants,
          'Vacancy': updatedVacancy,
          'Availability': availabilityStatus,
        });
      } else {
        // No dropped applicant found, apply as usual
        int updatedVacancy = (shiftDetails['Vacancy'] as int) - 1;
        String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

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