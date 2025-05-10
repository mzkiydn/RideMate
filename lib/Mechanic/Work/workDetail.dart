import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Work/workController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class WorkDetail extends StatefulWidget {
  final String shiftId;

  const WorkDetail({super.key, required this.shiftId});

  @override
  _WorkDetailState createState() => _WorkDetailState();
}

class _WorkDetailState extends State<WorkDetail> {
  final WorkController _controller = WorkController();
  bool _isLoading = true;
  Map<String, dynamic> shift = {};
  double _currentSliderValue = 2.5;

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
      print("Error fetching shift details: $e");
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: ${value ?? '-'}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(Map<String, dynamic> shift) async {
    double tempRating = _controller.currentSliderValue;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rate Workshop"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select a rating", style: TextStyle(fontSize: 20)),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 50,
                    label: tempRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        tempRating = value;
                      });
                    },
                  ),
                  Text(
                    'Rating: ${tempRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.rateWorkshop(
                  shift['Workshop ID'],
                  widget.shiftId,
                  tempRating,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thank you for rating!")),
                );
                _fetchShiftDetails(); // Refresh UI after rating
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterScaffold(
        customBarTitle: "Work Detail",
        leftCustomBarAction: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift['Workshop Name'] ?? 'Workshop',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.timer, "Operating Hours", shift['Operating Hours']),
                    _buildInfoRow(Icons.call, "Contact", shift['Contact']),
                    const Divider(height: 32, thickness: 1),
                    Text(
                      shift['Status'] ?? 'Status',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, "Date", shift['Date']),
                    _buildInfoRow(Icons.timer, "Shift", "${shift['Start']} - ${shift['End']}"),
                    _buildInfoRow(Icons.star, "Rating", (shift['Rate'] ?? 0.0).toStringAsFixed(1)),
                    _buildInfoRow(Icons.attach_money, "Salary", "RM${(shift['Salary'] ?? 0.0).toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),
            if (shift['Status'] == 'Completed' && shift["Workshop's Rate"] == 0.0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _showRatingDialog(shift);
                    },
                    icon: const Icon(Icons.star),
                    label: const Text("Rate"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ),
          ],
        ),
        currentIndex: 2,
      ),
    );
  }
}
