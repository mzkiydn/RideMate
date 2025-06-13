import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Shift/detailShift.dart';
import 'package:ridemate/Mechanic/Shift/shiftController.dart';
import 'package:ridemate/Mechanic/Shift/upcomingShift.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Shift extends StatefulWidget {
  const Shift({super.key});

  @override
  State<Shift> createState() => _ShiftState();
}

class _ShiftState extends State<Shift> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShiftController _shiftController = ShiftController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: "Shift",
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Current Shifts"),
              Tab(text: "Upcoming Shifts"),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<List<List<Map<String, dynamic>>>>(
                  future: Future.wait([
                    _shiftController.fetchCurrentShifts(),  // Accepted shifts
                    _shiftController.fetchShifts('Dropped'),  // Dropped shifts
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final currentShifts = snapshot.data![0];
                    final droppedShifts = snapshot.data![1];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timetable
                        if (currentShifts.isNotEmpty)
                          _buildTimetable(currentShifts)
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No current taken shifts.'),
                          ),

                        const SizedBox(height: 16.0),

                        // Taken shift cards
                        if (currentShifts.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              itemCount: currentShifts.length,
                              itemBuilder: (context, index) {
                                return _buildShiftCard(currentShifts[index], true);
                              },
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No current taken shifts.'),
                          ),

                        const SizedBox(height: 24.0),

                        // Dropped shifts section
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Dropped Shifts',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (droppedShifts.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              itemCount: droppedShifts.length,
                              itemBuilder: (context, index) {
                                return _buildShiftCard(droppedShifts[index], false);
                              },
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('You haven\'t dropped any shifts yet.'),
                          ),
                      ],
                    );
                  },
                ),
                UpcomingShifts(),
              ],
            ),
          ),
        ],
      ),
      currentIndex: 1,
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

  Widget _buildShiftCard(Map<String, dynamic> shift, bool isCurrent) {
    return Card(
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
            arguments: {'shiftId': shift['id']}, // Pass only the shift ID
          );
        },
      ),
    );
  }
}
