import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ShiftController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // fetch all shift
  Future<List<Map<String, dynamic>>> fetchShifts() async {
    return await _fetchShiftsByStatus('Available');
  }

  // fetch current week date
  Future<List<Map<String, dynamic>>> fetchCurrentShifts() async {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime sunday = monday.add(Duration(days: 6));
    String startOfWeek = DateFormat('yyyy-MM-dd').format(monday);
    String endOfWeek = DateFormat('yyyy-MM-dd').format(sunday);

    return await _fetchShiftsByApplicantStatus(['Accepted', 'Applied'], startOfWeek, endOfWeek);
  }

  // fetch the upcoming week
  Future<List<Map<String, dynamic>>> fetchUpcomingShifts() async {
    DateTime now = DateTime.now();
    DateTime nextMonday = now.add(Duration(days: 8 - now.weekday));
    DateTime nextSunday = nextMonday.add(Duration(days: 6));
    String startOfNextWeek = DateFormat('yyyy-MM-dd').format(nextMonday);
    String endOfNextWeek = DateFormat('yyyy-MM-dd').format(nextSunday);

    return await _fetchShiftsByApplicantStatus(['Accepted', 'Applied'], startOfNextWeek, endOfNextWeek);
  }

  // fetch shift with available vacancy
  Future<List<Map<String, dynamic>>> _fetchShiftsByStatus(String status) async {
    try {
      QuerySnapshot workshopQuery = await _firestore.collection('Workshop').get();
      List<Map<String, dynamic>> shifts = [];

      for (var workshop in workshopQuery.docs) {
        Map<String, dynamic> workshopData = await fetchWorkshopData(workshop.id);
        QuerySnapshot shiftQuery = await _firestore
            .collection('Workshop')
            .doc(workshop.id)
            .collection('Shifts')
            .where('Availability', isEqualTo: status)
            .get();

        shifts.addAll(_mapShifts(shiftQuery.docs, workshop.id, workshopData));
      }

      return shifts;
    } catch (e) {
      print('Error fetching shifts: $e');
      return [];
    }
  }

  // fetch shift with specific week and applicant status for specific applicant
  Future<List<Map<String, dynamic>>> _fetchShiftsByApplicantStatus(List<String> status, [String? startDate, String? endDate]) async {
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
            .where('Applicant', arrayContains: {'id': currentUserId, 'Status': status})
            // .where('Applicant.Status', isEqualTo: status)
            .get();

        List<Map<String, dynamic>> mappedShifts = _mapShifts(shiftQuery.docs, workshop.id, workshopData);
        if (startDate != null && endDate != null) {
          mappedShifts = mappedShifts.where((shift) =>
          DateFormat('yyyy-MM-dd').parse(shift['Date']).isAfter(DateFormat('yyyy-MM-dd').parse(startDate).subtract(Duration(days: 1))) &&
              DateFormat('yyyy-MM-dd').parse(shift['Date']).isBefore(DateFormat('yyyy-MM-dd').parse(endDate).add(Duration(days: 1)))
          ).toList();
        }
        shifts.addAll(mappedShifts);
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