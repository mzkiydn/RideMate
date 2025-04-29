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
        body: _buildCartList(),
        currentIndex: 2,
      ),
    );
  }

  Widget _buildCartList() {
    if (_controller.assignedCarts.isEmpty && _controller.workingCarts.isEmpty) {
      return const Center(child: Text("No task available"));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_controller.workingCarts.isNotEmpty) ...[
          _buildSectionTitle("Working"),
          for (var entry in _controller.workingCarts.entries)
            _buildCartCard(entry.key, entry.value),
        ],
        if (_controller.assignedCarts.isNotEmpty) ...[
          _buildSectionTitle("Assigned"),
          for (var entry in _controller.assignedCarts.entries)
            _buildCartCard(entry.key, entry.value),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCartCard(String cartId, Map<String, dynamic>? cartData) {
    if (cartData == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(cartData['OwnerName'] ?? "Unknown User"),
        subtitle: Text("Total Price: RM ${cartData['Price']?.toStringAsFixed(2) ?? "0.00"}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkDetail(cartId: cartId),
            ),
          );
        },
      ),
    );
  }
}

//button update status