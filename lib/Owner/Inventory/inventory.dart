import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Inventory/shiftList.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  final InventoryController _inventoryController = InventoryController();

  late Future<List<Map<String, dynamic>>> productsFuture;
  late Future<List<Map<String, dynamic>>> servicesFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = _inventoryController.fetchProducts();
    servicesFuture = _inventoryController.fetchServices();
  }

  // Function to show the initial dialog
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('What do you want to add?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showInventoryDialog(); // Show Inventory or Shift selection
                },
                child: const Text('Inventory'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/shift/detail',
                    arguments: {'shiftId': null}, // Navigate to DetailShift for adding a new shift
                  );
                },
                child: const Text('Shift'),
              ),
            ],
          ),
        );
      },
    );
  }


  // Function to show the dialog for Inventory type selection
  void _showInventoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('What type of inventory do you want to add?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToDetail(true); // Add product
                },
                child: const Text('Product'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToDetail(false); // Add service
                },
                child: const Text('Service'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigate to DetailInventory screen with the appropriate arguments
  void _navigateToDetail(bool isProduct) {
    Navigator.pushNamed(
      context,
      '/inventory/detail',
      arguments: {'itemId': null, 'isProduct': isProduct},
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MasterScaffold(
        customBarTitle: "Inventory",
        rightCustomBarAction: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _showAddDialog, // Show the initial add dialog
        ),
        body: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: "Inventory"),
                Tab(text: "Shift"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Inventory tab
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Label for Products
                        const Text(
                          'Products',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // List of products
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: productsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No products found');
                            }

                            final products = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Text(
                                          product['Name']!,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 100),
                                        Text(
                                          product['Stock'].toString(), // Display product stock
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                      onPressed: () {
                                        print('Product ID: ${product['id']}'); // Print the product ID
                                        Navigator.pushNamed(
                                          context,
                                          '/inventory/detail',
                                          arguments: {
                                            'itemId': product['id'], // Ensure the itemId is passed
                                            'isProduct': true, // true for product, false for service
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        // Label for Services
                        const Text(
                          'Services',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // List of services
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: servicesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No services found');
                            }

                            final services = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: services.length,
                              itemBuilder: (context, index) {
                                final service = services[index];
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Text(
                                          service['Name']!,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                      onPressed: () {
                                        print('Service ID: ${service['id']}'); // Print the service ID
                                        Navigator.pushNamed(
                                          context,
                                          '/inventory/detail',
                                          arguments: {
                                            'itemId': service['id'], // Ensure the itemId is passed
                                            'isProduct': false, // false for service
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Shift tab (assuming Shiftlist() is a predefined widget)
                  Shiftlist(),
                ],
              ),
            ),
          ],
        ),
        currentIndex: 1,
      ),
    );
  }
}
