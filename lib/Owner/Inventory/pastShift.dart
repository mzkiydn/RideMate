import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class PastShift extends StatefulWidget {
  final String shiftId;

  const PastShift({super.key, required this.shiftId});

  @override
  _PastShiftState createState() => _PastShiftState();
}

class _PastShiftState extends State<PastShift> {
  final InventoryController _controller = InventoryController();
  bool _isLoading = true;
  Map<String, dynamic> shift = {};

  @override
  void initState() {
    super.initState();
    _fetchShiftDetails();
  }

  Future<void> _fetchShiftDetails() async {
    try {
      Map<String, dynamic> shiftDetails = await _controller.fetchShiftDetails(widget.shiftId);
      setState(() {
        shift = shiftDetails;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching past shift details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Colors.amber, size: 16)),
        if (hasHalfStar) const Icon(Icons.star_half, color: Colors.amber, size: 16),
        ...List.generate(emptyStars, (_) => const Icon(Icons.star_border, color: Colors.amber, size: 16)),
      ],
    );
  }

  Widget _buildShiftDetailCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.timer, 'Start Time', "${shift['Start']} -  ${shift['End']}"),
            _infoRow(Icons.people, 'Vacancy', "${shift['Vacancy']?.toString()} Left"),
            _infoRow(Icons.calendar_today, 'Date', shift['Date']),
            _infoRow(Icons.attach_money, 'Rate', 'RM${(shift['Rate'] ?? 0.0).toStringAsFixed(2)} / Hour'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value ?? '-', style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    double workshopRate = (applicant['WorkshopRate'] ?? 0.0).toDouble();
    double mechanicRating = (applicant["Mechanic's Rate"] ?? 0.0).toDouble();
    String status = applicant['Status'] ?? '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              applicant['Mechanic Name'] ?? 'Applicant',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Salary: RM${(applicant['Salary'] ?? 0.0).toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Workshop Rate: '),
                Text(workshopRate.toStringAsFixed(1)),
                const SizedBox(width: 6),
                _buildStarRating(workshopRate),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Mechanic Rate: '),
                Text(mechanicRating.toStringAsFixed(1)),
                const SizedBox(width: 6),
                _buildStarRating(mechanicRating),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status: $status'),
                if (status == 'Completed' || status == 'Done')
                  ElevatedButton.icon(
                    onPressed: () async {
                      final applicantId = applicant['Mechanic ID'];

                      final shiftDetails = await _controller.fetchShiftDetails(widget.shiftId);

                      await _controller.generateAndPrintReceipt({
                        ...shiftDetails,
                      },
                        applicantId,
                      );
                    },

                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterScaffold(
        customBarTitle: "Past Shift",
        leftCustomBarAction: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift Details',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildShiftDetailCard(),
              const SizedBox(height: 10),
              Text(
                'Applicants',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.from(
                (shift['Applicants'] as List<dynamic>? ?? [])
                    .map((app) => _buildApplicantCard(Map<String, dynamic>.from(app))),
              ),
              if ((shift['Applicants'] as List<dynamic>?)?.isEmpty ?? true)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text('No applicants found for this shift.'),
                ),
            ],
          ),
        ),
        currentIndex: 2,
      ),
    );
  }
}
