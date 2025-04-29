import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Work/workController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class WorkDetail extends StatefulWidget {
  final String cartId;
  const WorkDetail({super.key, required this.cartId});

  @override
  _WorkDetailState createState() => _WorkDetailState();
}

class _WorkDetailState extends State<WorkDetail> {
  final WorkController _controller = WorkController();
  bool _isLoading = true;
  String? _selectedMechanic; // Holds the currently selected mechanic ID

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    await _controller.fetchShiftWorkshop(FirebaseAuth.instance.currentUser?.uid ?? '');
    // await _controller.fetchMechanics();
    await _controller.fetchAssignedCarts();
    await _controller.fetchWorkingCarts();
    await _controller.fetchCartDetails(widget.cartId);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterScaffold(
        customBarTitle: "Work",
        leftCustomBarAction: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssignMechanicCard(),
              const SizedBox(height: 10),
              _buildCartDetailsCard(),
            ],
          ),
        ),
        currentIndex: 2,
      ),
    );
  }

  Widget _buildAssignMechanicCard() {
    String status = _controller.cartDetails['Status'] ?? 'Unknown';
    String? cart = _controller.cartDetails['Cart'];

    return SizedBox(
      width: 400,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status == 'Working' ? "Working Task" : "Assigned Task",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cart: ${cart ?? 'Unknown'}",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text("Status: $status", style: const TextStyle(fontSize: 14)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartDetailsCard() {
    String status = _controller.cartDetails['Status'] ?? 'Unknown';
    bool showAssignButton = !(status == 'Assigned' || status == 'Working');

    return SizedBox(
      width: 400, // Same fixed width as AssignMechanicCard
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Customer: ${_controller.cartDetails['Customer'] ?? 'Unknown'}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              if (showAssignButton)
                Text("Status: ${_controller.cartDetails['Status'] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 14)),
              const Divider(),
              const Text("Products:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_controller.cartDetails['Products'] is Map && _controller.cartDetails['Products'].isNotEmpty)
                Column(
                  children: _controller.cartDetails['Products'].entries.map<Widget>((entry) {
                    final product = entry.value;
                    final String productId = entry.key;
                    final int quantity = product['Quantity'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(product['Name'] ?? 'Unknown')),
                          Expanded(
                            flex: 1,
                            child: status == 'Working'
                                ? Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _controller.updateQuantity(
                                      _controller.cartDetails['WorkshopId'], productId, -1, setState),
                                ),
                                Text("$quantity", style: const TextStyle(fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _controller.updateQuantity(
                                      _controller.cartDetails['WorkshopId'], productId, 1, setState),
                                ),
                              ],
                            )
                                : Text("$quantity"),
                          ),
                          Expanded(flex: 1, child: Text("RM${product['Price']}")),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const Text("No products available"),
              const SizedBox(height: 5),
              const Text("Services:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_controller.cartDetails['Services'] is Map && _controller.cartDetails['Services'].isNotEmpty)
                Column(
                  children: _controller.cartDetails['Services'].entries.map<Widget>((entry) {
                    final service = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(service['Name'] ?? 'Unknown')),
                          const Expanded(flex: 1, child: Text("")),
                          Expanded(flex: 1, child: Text("RM${service['Price']}")),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const Text("No services available"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Price:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("RM${_controller.cartDetails['Price']?.toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              if (showAssignButton)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () =>
                          _controller.updateStatus(widget.cartId, status == 'Assigned' ? 'Start' : 'Complete'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(status == 'Assigned' ? 'Start' : 'Complete'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

//renderflow