import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';

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
          _nameController.text = item?['Name'] ?? ''; // Default to empty string if null
          _descriptionController.text = item?['Description'] ?? ''; // Default to empty string if null
          _priceController.text = (item?['Price'] ?? 0.0).toString(); // Default to 0.0 if null
          if (widget.isProduct) {
            _stockController.text = (item?['Stock'] ?? 0).toString(); // Default to 0 if null for products
          }
          _isAvailable = item?['Availability'] ?? true; // Default to true if null
          _pageTitle = item?['Name'] ?? 'Item Details'; // Use product/service name or 'Item Details'
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
    final isAvailable = _isAvailable;

    if (widget.isProduct) {
      if (widget.itemId == null) {
        await InventoryController().addProduct(name, description, price, stock!, isAvailable);
      } else {
        await InventoryController().updateProduct(widget.itemId!, name, description, price, stock!, isAvailable);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? _pageTitle : 'Edit $_pageTitle'),
        actions: [
          if (widget.itemId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteItem,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            if (widget.isProduct) ...[ // Only show stock field for product
              TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
            ],
            SwitchListTile(
              title: const Text('Available'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveItem,
              child: Text(widget.itemId == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
