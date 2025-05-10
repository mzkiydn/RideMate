import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Work/workController.dart';
import 'package:ridemate/Mechanic/Work/workDetail.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Work extends StatefulWidget {
  const Work({Key? key}) : super(key: key);

  @override
  _WorkState createState() => _WorkState();
}

class _WorkState extends State<Work> {
  final WorkController _controller = WorkController();

  @override
  void initState() {
    super.initState();
    _controller.initAssignData().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterScaffold(
        customBarTitle: "Work",
        body: _buildWorkBody(),
        currentIndex: 2,
      ),
    );
  }

  Widget _buildWorkBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _controller.initAssignData();
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMechanicInfo(),
          const SizedBox(height: 16),

          if (_controller.filteredShifts.isNotEmpty) ...[
            _buildSectionTitle("My Shifts"),
            ..._controller.filteredShifts.map(_buildShiftCard).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMechanicInfo() {
    final m = _controller.mechanicDetails;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m['Name'] ?? 'Unknown',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Phone: ${m['Phone'] ?? '-'}"),
            Text("Rating: ${m['Rating']?.toStringAsFixed(1) ?? '0.0'} "
                "(${m['Rating Count'] ?? 0} shifts)"),
            const SizedBox(height: 8),
            Text("Total Salary: RM ${_controller.totalSalary.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(shift['Workshop Name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salary: RM${(shift['Salary'] ?? 0.0).toStringAsFixed(1)}'),
            Text('Rating: ${(shift['Rate'] ?? 0.0).toStringAsFixed(1)}'),
            Text("Date: ${shift['Formatted Date']}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _controller.getStatusColor(shift['Status']),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            shift['Status'],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        onTap: () {
          final shiftId = shift['id'] ?? 'defaultId';
          Navigator.pushNamed(
            context,
            '/workDetail',
            arguments: {'shiftId': shiftId},
          );
        },
      ),
    );
  }
}
