import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridemate/Template/masterScaffold.dart';
import 'package:ridemate/Motorcyclist/Cart/cartController.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<Cart> {
  final CartController _controller = CartController();

  @override
  void initState() {
    super.initState();
    _controller.initCart().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: "Cart",
      body: _controller.cartData.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : ListView.builder(
        itemCount: _controller.cartData.keys.length,
        itemBuilder: (context, index) {
          String workshopId = _controller.cartData.keys.elementAt(index);
          var workshop = _controller.cartData[workshopId];
          return _buildWorkshopCard(workshopId, workshop);
        },
      ),
      currentIndex: 1,
    );
  }

  Widget _buildWorkshopCard(String workshopId, Map<String, dynamic> workshop) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ExpansionTile(
        title: Text(
          workshop['workshopName'] ?? "Unknown Workshop",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [_buildCartDetails(workshopId, workshop)],
      ),
    );
  }

  Widget _buildCartDetails(String workshopId, Map<String, dynamic> workshop) {
    Map<String, int> productQuantities = workshop['productQuantities'];
    List<String> serviceIds = workshop['serviceIds'];
    double totalPrice = workshop['totalPrice'];
    String cartStatus = workshop['status'] ?? "Pending";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Products", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...productQuantities.entries.map((entry) => _buildCartItem(workshopId, entry.key, entry.value)),
          const SizedBox(height: 10),
          const Text("Services", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...serviceIds.map((serviceId) => _buildServiceItem(workshopId, serviceId)),
          const Divider(thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("RM ${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          // Arrive Button
          Align(
            alignment: Alignment.centerRight, // Align to the right
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.25, // Quarter width of screen
              child: ElevatedButton(
                onPressed: cartStatus == "Arrived"
                    ? null
                    : () => _controller.markCartAsArrived(workshopId, setState, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cartStatus == "Arrived" ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  cartStatus == "Arrived" ? "Arrived" : "Arrived",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(String workshopId, String productId, int quantity) {
    return FutureBuilder<DocumentSnapshot>(
      future: _controller.getProduct(workshopId, productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        var productData = snapshot.data!.data() as Map<String, dynamic>?;
        if (productData == null) return const SizedBox.shrink();

        double productPrice = (productData['Price'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(productData['Name'], style: const TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "RM ${productPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _controller.updateQuantity(workshopId, productId, -1, setState),
                  ),
                  Text("$quantity", style: const TextStyle(fontSize: 14)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _controller.updateQuantity(workshopId, productId, 1, setState),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(String workshopId, String serviceId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _controller.getService(workshopId, serviceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        var serviceData = snapshot.data!.data() as Map<String, dynamic>?;
        if (serviceData == null) return const SizedBox.shrink();

        double servicePrice = (serviceData['Price'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(serviceData['Name'], style: const TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "RM ${servicePrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 55),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _controller.updateQuantity(workshopId, serviceId, -1, setState, isService: true, price: servicePrice),
              ),
            ],
          ),
        );
      },
    );
  }
}
