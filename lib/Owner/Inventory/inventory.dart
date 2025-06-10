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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding inside the dialog
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'What do you want to add?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Inline buttons with equal size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Inventory Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showInventoryDialog(); // Show Inventory or Shift selection
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14), // Button padding
                        ),
                        child: const Text('Inventory'),
                      ),
                    ),
                    const SizedBox(width: 10), // Space between buttons
                    // Shift Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/shift/detail',
                            arguments: {'shiftId': null}, // Navigate to DetailShift
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14), // Button padding
                        ),
                        child: const Text('Shift'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding inside the dialog
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'What type of inventory do you want to add?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Inline buttons with equal size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToDetail(true); // Add product
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14), // Button padding
                        ),
                        child: const Text('Product'),
                      ),
                    ),
                    const SizedBox(width: 10), // Space between buttons
                    // Service Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToDetail(false); // Add service
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14), // Button padding
                        ),
                        child: const Text('Service'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

                            final allProducts = snapshot.data!;
                            final availableProducts = allProducts.where((p) => p['Availability'] == true).toList();
                            final unavailableProducts = allProducts.where((p) => p['Availability'] == false).toList();
                            final products = [...availableProducts, ...unavailableProducts];
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final isAvailable = product['Availability'] == true;
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  color: isAvailable ? null : Colors.grey.shade300,
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['Name']!,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Stock: ${product['Stock']}',
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

                            final allServices = snapshot.data!;
                            final availableServices = allServices.where((s) => s['Availability'] == true).toList();
                            final unavailableServices = allServices.where((s) => s['Availability'] == false).toList();
                            final services = [...availableServices, ...unavailableServices];
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: services.length,
                              itemBuilder: (context, index) {
                                final service = services[index];
                                final isAvailable = service['Availability'] == true;
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  color: isAvailable ? null : Colors.grey.shade300,
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            service['Name']!,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
