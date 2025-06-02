import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';

class Shiftlist extends StatefulWidget {
  @override
  _ShiftlistState createState() => _ShiftlistState();
}

class _ShiftlistState extends State<Shiftlist> {
  final InventoryController _inventoryController = InventoryController();
  late Future<List<Map<String, dynamic>>> shiftsFuture;

  @override
  void initState() {
    super.initState();
    shiftsFuture = _inventoryController.fetchShifts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: shiftsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No shifts available'));
                }

                final shifts = snapshot.data!;

                // Separate ongoing and past shifts by comparing shift['Day'] with today's date
                // Assuming shift['Day'] is a String date like '2025-06-02' or a DateTime object
                final now = DateTime.now();
                List<Map<String, dynamic>> ongoingShifts = [];
                List<Map<String, dynamic>> pastShifts = [];

                final today = DateTime(now.year, now.month, now.day);

                for (var shift in shifts) {
                  DateTime shiftDate;
                  try {
                    if (shift['Date'] is String) {
                      shiftDate = DateTime.parse(shift['Date']);
                    } else if (shift['Date'] is DateTime) {
                      shiftDate = shift['Date'];
                    } else {
                      shiftDate = today;
                    }
                  } catch (_) {
                    shiftDate = today;
                  }

                  // reset shiftDate to midnight for comparison
                  shiftDate = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);

                  if (!shiftDate.isBefore(today)) {
                    ongoingShifts.add(shift);
                  } else {
                    pastShifts.add(shift);
                  }
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const Text(
                      'Ongoing Shifts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...ongoingShifts.map((shift) => _buildShiftCard(context, shift, false)),
                    const SizedBox(height: 16),
                    const Text(
                      'Past Shifts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...pastShifts.map((shift) => _buildShiftCard(context, shift, true)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Map<String, dynamic> shift, bool isPast) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${shift['Day']} - ${shift['Start']} to ${shift['End']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Vacancies: ${shift['Vacancy']} | Rate: RM ${shift['Rate']}/hr",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.blue),
          onPressed: () {
            if (isPast) {
              Navigator.pushNamed(
                context,
                '/pastShift/detail',
                arguments: {'shiftId': shift['id']},
              );
            } else {
              Navigator.pushNamed(
                context,
                '/shift/detail',
                arguments: {'shiftId': shift['id']},
              );
            }
          },
        ),
      ),
    );
  }
}
