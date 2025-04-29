import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Shift/detailShift.dart';
import 'package:ridemate/Mechanic/Shift/shiftController.dart';

class UpcomingShifts extends StatelessWidget {
  final ShiftController _controller = ShiftController();

  UpcomingShifts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _controller.fetchUpcomingShifts(), // Calls _fetchShiftsByApplicantStatus
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No upcoming shifts available.'));
            }

            final upcomingShifts = snapshot.data!;
            return _buildTimetable(upcomingShifts);
          },
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _controller.fetchShifts(), // Calls _fetchShiftsByStatus
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No available shifts.'));
              }

              final availableShifts = snapshot.data!;
              return ListView.builder(
                itemCount: availableShifts.length,
                itemBuilder: (context, index) {
                  final shift = availableShifts[index];
                  return _buildShiftCard(context, shift);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimetable(List<Map<String, dynamic>> shifts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Workshop')),
            DataColumn(label: Text('Monday')),
            DataColumn(label: Text('Tuesday')),
            DataColumn(label: Text('Wednesday')),
            DataColumn(label: Text('Thursday')),
            DataColumn(label: Text('Friday')),
            DataColumn(label: Text('Saturday')),
            DataColumn(label: Text('Sunday')),
          ],
          rows: shifts.map((shift) {
            return DataRow(
              cells: [
                DataCell(Text(shift['Name'] ?? 'Unknown')),
                ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                    .map((day) {
                  final shiftTime = shift['Day'] == day
                      ? "${shift['Start']} - ${shift['End']}"
                      : '-';
                  return DataCell(Text(shiftTime));
                }).toList(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Map<String, dynamic> shift) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.blue),
        title: Text(
          shift['Name'] ?? 'No name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${shift['Date']} - ${shift['Date']}'),
            Text('Shift: ${shift['Start']} - ${shift['End']}'),
            Text('Rate: RM${shift['Rate']} / hour'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          print("Shift ID: ${shift['id']}"); // Print only the shift ID

          Navigator.pushNamed(
            context,
            '/shiftDetail',
            arguments: {'shiftId': shift['id']}, // Pass only the shift ID
          );
        },
      ),
    );
  }
}
