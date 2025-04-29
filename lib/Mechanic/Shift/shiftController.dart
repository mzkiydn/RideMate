import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

      // Convert startDate and endDate to DateTime objects
      DateTime? start = startDate != null ? DateFormat('yyyy-MM-dd').parse(startDate) : null;
      DateTime? end = endDate != null ? DateFormat('yyyy-MM-dd').parse(endDate) : null;

      List<Map<String, dynamic>> shifts = [];

      // Loop from startDate to endDate
      for (DateTime? currentDay = start; currentDay!.isBefore(end!.add(Duration(days: 1))); currentDay = currentDay.add(Duration(days: 1))) {

        // Format the current date to match the shift date format
        String currentDayStr = DateFormat('yyyy-MM-dd').format(currentDay);

        // Query the workshops
        QuerySnapshot workshopQuery = await _firestore.collection('Workshop').get();

        for (var workshop in workshopQuery.docs) {
          Map<String, dynamic> workshopData = await fetchWorkshopData(workshop.id);

          // Query shifts where the applicant status is 'Accepted' or 'Applied' for the current day
          QuerySnapshot shiftQuery = await _firestore
              .collection('Workshop')
              .doc(workshop.id)
              .collection('Shifts')
              .where('Date', isEqualTo: currentDayStr)
              .where('Applicant', arrayContainsAny: [
                {'id': currentUserId, 'Status': 'Accepted'},
                {'id': currentUserId, 'Status': 'Applied'}
              ])
              .get();

          List<Map<String, dynamic>> mappedShifts = _mapShifts(shiftQuery.docs, workshop.id, workshopData);

          // Filter shifts to match the current day
          mappedShifts = mappedShifts.where((shift) {
            DateTime shiftDate = DateFormat('yyyy-MM-dd').parse(shift['Date']);
            return shiftDate.isAtSameMomentAs(currentDay!); // Only include shifts on the current day
          }).toList();

          shifts.addAll(mappedShifts);
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

          return shiftData;
        }
      }
      return null; // Shift not found in any workshop
    } catch (e) {
      print('Error fetching shift details: $e');
      return null;
    }
  }


}