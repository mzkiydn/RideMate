import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class DetailInventory extends StatefulWidget {
  final String? itemId;
  final bool isProduct; // true for product, false for service

  const DetailInventory({
    super.key,
    this.itemId,
    required this.isProduct,
  });

  @override
  _DetailInventoryState createState() => _DetailInventoryState();
}

class _DetailInventoryState extends State<DetailInventory> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  bool _isAvailable = true;
  String _pageTitle = '';

  // For dropdown selection
  String? _selectedMotorcycle;
  // common motorcycle in Malaysia
  final List<String> _motorcycle = ['Wave', 'EX5', 'RS150', 'RSX', 'Dash', 'Beat', 'Vario',
    'LC135', 'Y15', 'NVX', 'Y16', 'Lagenda', 'Avantiz', 'RXZ', '125ZR'];

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadItemDetails();
    } else {
      _pageTitle = widget.isProduct ? 'Add Product' : 'Add Service'; // Add screen
    }
  }

  // Fetch the item details if editing an existing item
  Future<void> _loadItemDetails() async {
    if (widget.itemId == null) {
      print("Item ID is null, skipping load for new item.");
      return; // If no itemId, we don't need to load anything.
    }

    Map<String, dynamic>? item;
    try {
      if (widget.isProduct) {
        item = await InventoryController().getProductById(widget.itemId!);
      } else {
        item = await InventoryController().getServiceById(widget.itemId!);
      }

      if (item != null) {
        setState(() {
          _nameController.text = item?['Name'] ?? '';
          _descriptionController.text = item?['Description'] ?? '';
          _priceController.text = (item?['Price'] ?? 0.0).toString();
          if (widget.isProduct) {
            _stockController.text = (item?['Stock'] ?? 0).toString();
          }
          _isAvailable = item?['Availability'] ?? true;
          _selectedMotorcycle = item?['Motorcycle'];
          _pageTitle = item?['Name'] ?? 'Item Details';
        });
      } else {
        setState(() {
          _pageTitle = 'Item not found';
        });
      }
    } catch (e) {
      setState(() {
        _pageTitle = 'Error loading item';
      });
      print('Error loading item: $e');
    }
  }

  // Save the product or service (add or update)
  Future<void> _saveItem() async {
    final name = _nameController.text;
    final description = _descriptionController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final stock = widget.isProduct ? (int.tryParse(_stockController.text) ?? 0) : null;
    final motorcycle = _selectedMotorcycle;
    final isAvailable = _isAvailable;

    if (widget.isProduct) {
      if (widget.itemId == null) {
        await InventoryController().addProduct(name, description, price, stock!, isAvailable, motorcycle);
      } else {
        await InventoryController().updateProduct(widget.itemId!, name, description, price, stock!, isAvailable, motorcycle);
      }
    } else {
      if (widget.itemId == null) {
        await InventoryController().addService(name, description, price, isAvailable);
      } else {
        await InventoryController().updateService(widget.itemId!, name, description, price, isAvailable);
      }
    }

    Navigator.pop(context); // Go back to the Inventory screen
  }

  Future<void> _deleteItem() async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this item? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        if (widget.isProduct) {
          await InventoryController().deleteProduct(widget.itemId!);
        } else {
          await InventoryController().deleteService(widget.itemId!);
        }
        Navigator.pop(context); // Go back after deletion
      } catch (e) {
        print("Error deleting item: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting item")),
        );
      }
    }
  }

  // Restrict input to numeric only (int or double)
  void _onPriceChanged(String value) {
    if (value.isNotEmpty && double.tryParse(value) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number for price")),
      );
    }
  }

  void _onStockChanged(String value) {
    if (value.isNotEmpty && int.tryParse(value) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number for stock")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: widget.itemId == null ? _pageTitle : 'Edit $_pageTitle',
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding to prevent overlap
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _onPriceChanged,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.isProduct) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onStockChanged,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: _motorcycle.map((category) {
                                  return ListTile(
                                    title: Text(category),
                                    onTap: () {
                                      setState(() {
                                        _selectedMotorcycle = category;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: TextEditingController(text: _selectedMotorcycle),
                          decoration: InputDecoration(
                            labelText: 'Select Motorcycle',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Available'),
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.itemId == null ? 'Add' : 'Save'),
                  ),
                ),
                if (widget.itemId != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete Item'),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
      currentIndex: 1,
    );
  }
}
