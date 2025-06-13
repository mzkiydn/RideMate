import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Shift/shiftController.dart';

class UpcomingShifts extends StatelessWidget {
  final ShiftController _controller = ShiftController();

  UpcomingShifts({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: Future.wait([
        _controller.fetchUpcomingShifts(), // Taken shifts (applied/accepted)
        _controller.fetchShifts('Available'), // Available shifts
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No shift data found.'));
        }

        final takenShifts = snapshot.data![0];
        final availableShifts = snapshot.data![1];

        return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timetable
                if (takenShifts.isNotEmpty)
                  _buildTimetable(takenShifts)
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No upcoming taken shifts.'),
                  ),

                const SizedBox(height: 16.0),

                // Taken Shift Cards
                if (takenShifts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('You haven\'t taken any shifts yet.'),
                  )
                else
                  ...takenShifts.map((shift) => _buildShiftCard(context, shift)),

                const SizedBox(height: 24.0),

                // Available Shift Cards
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Available Shifts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (availableShifts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('No available shifts at the moment.'),
                  )
                else
                  ...availableShifts.map((shift) => _buildShiftCard(context, shift)),
              ],
            ),
          );
      },
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
                DataCell(Text(shift['workshopData']['Name'] ?? 'Unknown')),
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
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.blue),
        title: Text(
          shift['workshopData']['Name'] ?? 'No name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${shift['Day']} - ${shift['Date']}'),
            Text('Shift: ${shift['Start']} - ${shift['End']}'),
            Text('Rate: RM${shift['Rate']} / hour'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/shiftDetail',
            arguments: {'shiftId': shift['id']},
          );
        },
      ),
    );
  }
}
