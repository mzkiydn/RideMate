import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Assign/assignController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Assign extends StatefulWidget {
  const Assign({Key? key}) : super(key: key);

  @override
  _AssignState createState() => _AssignState();
}

class _AssignState extends State<Assign> with TickerProviderStateMixin {
  final AssignController _controller = AssignController();
  TabController? _tabController; // <-- Make it nullable

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _controller.initAttendanceData().then((_) {
      if (mounted) {
        setState(() {}); // safer: only setState if still mounted
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose(); // <-- Don't forget to dispose controller!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterScaffold(
        customBarTitle: "Assignation",
        body: _tabController == null
            ? const Center(child: CircularProgressIndicator()) // while initializing
            : Column(
          children: [
            TabBar(
              controller: _tabController!,
              tabs: const [
                Tab(text: "Attendance"),
                Tab(text: "Payment"),
              ],
              labelColor: Colors.black,
              indicatorColor: Colors.blue,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                children: [
                  _buildAttendanceTab(),
                  _buildPaymentTab(),
                ],
              ),
            ),
          ],
        ),
        currentIndex: 2,
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle("Today's Attendance"),
        if (_controller.todayAttendance.isEmpty)
          const Text("No today's attendance"),
        for (var entry in _controller.todayAttendance.entries)
          _buildAttendanceCard(entry.key, entry.value, isToday: true),

        const SizedBox(height: 16),
        _buildSectionTitle("Upcoming Approvals"),
        if (_controller.upcomingAttendance.isEmpty)
          const Text("No upcoming attendance"),
        for (var entry in _controller.upcomingAttendance.entries)
          _buildAttendanceCard(entry.key, entry.value, isToday: false),
      ],
    );
  }

  Widget _buildPaymentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle("Pending Payment"),
        if (_controller.pendingPayment.isEmpty)
          const Text("No pending payments"),
        for (var entry in _controller.pendingPayment.entries)
          _buildPaymentCard(entry.key, entry.value, isPending: true),

        const SizedBox(height: 16),
        _buildSectionTitle("Completed Payment"),
        if (_controller.completedPayment.isEmpty)
          const Text("No completed payments"),
        for (var entry in _controller.completedPayment.entries)
          _buildPaymentCard(entry.key, entry.value, isPending: false),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAttendanceCard(String shiftId, Map<String, dynamic> data, {required bool isToday}) {
    // Ensure you have all necessary data
    String workshopId = data['Workshop ID'] ?? 'N/A';
    String applicantId = data['Applicant ID'] ?? 'N/A';
    String shiftId = data['Shift ID'] ?? 'N/A';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(data['Name'] ?? "Unknown Mechanic"),
        subtitle: Text(
          isToday
              ? "Shift Time: ${data['Start'] ?? 'N/A'} - ${data['End'] ?? 'N/A'}"
              : "Phone: ${data['Phone Number'] ?? '-'} | Rating: ${data['Rating']?.toStringAsFixed(1) ?? '-'}",
        ),
        trailing: isToday
            ? ElevatedButton(
          onPressed: () {
            // Pass workshopId, shiftId, and applicantId when the button is clicked
            print("Verify button pressed for Shift ID: $shiftId");
            print("Data for verification: ${data}");

            if (data['Workshop ID'] != null && data['Applicant ID'] != null && data['Rate'] != null) {
              print("Calling verifyAttendance with WorkshopId: $workshopId, ShiftId: $shiftId, ApplicantId: $applicantId, Rate: ${data['Rate']?.toDouble()}");

              // Call the method to verify attendance and calculate salary
              _controller.verifyAttendance(
                workshopId,
                shiftId, // ShiftId
                applicantId, // Pass specific applicant ID
                data['Rate']?.toDouble() ?? 0.0,
              );
            } else {
              // Handle missing data case
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Missing required data for verification')),
              );
            }
          },
          child: const Text("Verify"),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                _controller.approveApplicant(
                  workshopId, // Pass workshopId
                  shiftId, // Pass shiftId
                  applicantId, // Pass applicantId
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.blue),
              onPressed: () {
                if (data['Phone Number'] != null) {
                  _controller.callMechanic(data['Phone Number']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(String id, Map<String, dynamic> data, {required bool isPending}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(data['Name'] ?? "Unknown Mechanic"),
        subtitle: Text("Salary: RM ${data['Salary']?.toStringAsFixed(2) ?? "0.00"}"),
        trailing: ElevatedButton(
          onPressed: () async {
            if (isPending) {
              // Pay mechanic
              _controller.payMechanic(
                data['Workshop ID'],
                id,
                data['Salary']?.toDouble() ?? 0.0,
              );
            } else {
              // Reset the slider value first
              _controller.currentSliderValue = 2.5; // default middle

              double? rating = await showDialog<double>(
                context: context,
                builder: (context) {
                  double tempRating = _controller.currentSliderValue; // temp slider value
                  return AlertDialog(
                    title: const Text('Rate Mechanic'),
                    content: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Select a rating:'),
                            Slider(
                              min: 0,
                              max: 5,
                              divisions: 10,
                              value: tempRating,
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
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('Submit'),
                        onPressed: () => Navigator.pop(context, tempRating),
                      ),
                    ],
                  );
                },
              );


              if (rating != null) {
                String? mechanicId = data['Applicant ID'];
                if (mechanicId != null) {
                  await _controller.rateMechanic(
                    mechanicId,
                    data['Workshop ID'],
                    id,
                    customRating: rating,
                  );
                } else {
                  print('MechanicId is null. Cannot rate mechanic.');
                }
              }
            }
          },

          child: Text(isPending ? "Pay" : "Rate"),
        ),
      ),
    );
  }
}
