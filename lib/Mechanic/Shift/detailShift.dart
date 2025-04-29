import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Shift/shiftController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class ShiftDetail extends StatefulWidget {
  final String shiftId;

  const ShiftDetail({super.key, required this.shiftId});

  @override
  _ShiftDetailState createState() => _ShiftDetailState();
}

class _ShiftDetailState extends State<ShiftDetail> {
  Map<String, dynamic>? shiftDetails;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchShiftDetails();
  }

  Future<void> _fetchShiftDetails() async {
    ShiftController shiftController = ShiftController();
    final data = await shiftController.fetchShiftById(widget.shiftId);

    setState(() {
      shiftDetails = data;
      isLoading = false;
    });
  }

  Future<void> _applyForShift() async {
    if (shiftDetails == null || currentUserId == null) return;

    try {
      final shiftRef = FirebaseFirestore.instance
          .collection('Workshop')
          .doc(shiftDetails!['workshopId'])
          .collection('Shifts')
          .doc(widget.shiftId);

      // Get current applicants
      List<dynamic> applicants = List.from(shiftDetails!['Applicant'] ?? []);

      // Look for a dropped applicant to replace
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

        int updatedVacancy = (shiftDetails!['Vacancy'] as int) - 1;
        String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

        await shiftRef.update({
          'Applicant': applicants,
          'Vacancy': updatedVacancy,
          'Availability': availabilityStatus,
        });

        setState(() {
          shiftDetails!['Applicant'] = applicants;
          shiftDetails!['Vacancy'] = updatedVacancy;
          shiftDetails!['Availability'] = availabilityStatus;
        });

      } else {
        // No dropped applicant found, apply as usual
        int updatedVacancy = (shiftDetails!['Vacancy'] as int) - 1;
        String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';

        await shiftRef.update({
          'Applicant': FieldValue.arrayUnion([
            {'id': currentUserId, 'Status': applicantStatus}
          ]),
          'Vacancy': updatedVacancy,
          'Availability': availabilityStatus,
        });

        setState(() {
          shiftDetails!['Applicant'].add({'id': currentUserId, 'Status': applicantStatus});
          shiftDetails!['Vacancy'] = updatedVacancy;
          shiftDetails!['Availability'] = availabilityStatus;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift applied successfully!")),
      );
    } catch (e) {
      print('Error applying for shift: $e');
    }
  }

  Future<void> _dropShift() async {
    if (shiftDetails == null || currentUserId == null) return;

    try {
      final shiftRef = FirebaseFirestore.instance
          .collection('Workshop')
          .doc(shiftDetails!['workshopId'])
          .collection('Shifts')
          .doc(widget.shiftId);

      List<dynamic> updatedApplicants = List.from(shiftDetails!['Applicant'] ?? []);

      for (var applicant in updatedApplicants) {
        if (applicant['id'] == currentUserId) {
          applicant['Status'] = 'Dropped';
          break;
        }
      }

      int updatedVacancy = (shiftDetails!['Vacancy'] as int) + 1;
      String availabilityStatus = updatedVacancy == 0 ? 'Full' : 'Available';


      await shiftRef.update({
        'Applicant': updatedApplicants,
        'Vacancy': updatedVacancy,
        'Availability': availabilityStatus,
      });

      setState(() {
        shiftDetails!['Applicant'] = updatedApplicants;
        shiftDetails!['Vacancy'] = updatedVacancy;
        shiftDetails!['Availability'] = availabilityStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have dropped the shift.")),
      );
    } catch (e) {
      print("Error dropping shift: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: shiftDetails?['Name'] ?? "Shift Details",
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shiftDetails == null
          ? const Center(child: Text("Shift not found."))
          : _buildShiftDetail(),
      currentIndex: 1,
    );
  }

  Widget _buildShiftDetail() {
    String? applicantStatus;
    if (shiftDetails?['Applicant'] is List) {
      for (var applicant in shiftDetails?['Applicant']) {
        if (applicant['id'] == currentUserId) {
          applicantStatus = applicant['Status'];
          break;
        }
      }
    }

    bool isAvailable = shiftDetails?['Vacancy'] > 0;

    List<String> jobScopes;
    if (shiftDetails?['Scope'] is String) {
      jobScopes = [shiftDetails?['Scope'] as String];
    } else if (shiftDetails?['Scope'] is List) {
      jobScopes = List<String>.from(shiftDetails?['Scope'] as List);
    } else {
      jobScopes = [];
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.calendar_today, "Date", shiftDetails?['Date']),
          _buildInfoRow(Icons.access_time, "Shift Time",
              "${shiftDetails?['Start']} - ${shiftDetails?['End']}"),
          _buildInfoRow(Icons.attach_money, "Salary Rate",
              "RM${shiftDetails?['Rate']} per hour"),
          _buildInfoRow(Icons.people, "Vacancies Left",
              shiftDetails?['Vacancy'].toString()),
          _buildInfoRow(Icons.warning, "Availability Status",
              shiftDetails?['Availability'] ?? 'Available'),
          const SizedBox(height: 16),
          const Text("Job Scope", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...jobScopes.map((scope) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(scope)),
              ],
            ),
          )),

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (applicantStatus == "Accepted") {
                  _dropShift();
                } else if (applicantStatus != "Applied" && isAvailable) {
                  _applyForShift();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: applicantStatus == "Accepted"
                    ? Colors.red
                    : applicantStatus == "Applied"
                    ? Colors.grey
                    : Colors.blue,
              ),
              child: Text(
                applicantStatus == "Accepted"
                    ? "Drop"
                    : applicantStatus == "Applied"
                    ? "Applied"
                    : "Take Shift",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text("$label: ${value ?? '-'}"),
        ],
      ),
    );
  }
}
