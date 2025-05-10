import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridemate/Motorcyclist/Market/marketController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class MarketDetail extends StatefulWidget {
  final String? marketId;

  const MarketDetail({super.key, this.marketId});

  @override
  _MarketDetailState createState() => _MarketDetailState();
}

class _MarketDetailState extends State<MarketDetail> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _pageTitle = 'Add Product';

  @override
  void initState() {
    super.initState();
    if (widget.marketId != null) {
      _loadMarketDetails();
    }
  }

  // Load product details from the MarketController
  Future<void> _loadMarketDetails() async {
    if (widget.marketId == null) return;

    try {
      // Fetch product details using the MarketController
      Map<String, dynamic>? product = await MarketController().getMarketProductById(widget.marketId!);
      if (product != null) {
        setState(() {
          _nameController.text = product['Name'] ?? '';
          _descriptionController.text = product['Description'] ?? '';
          _priceController.text = (product['Price'] ?? 0.00).toString();
          _pageTitle = 'Edit Product';
        });
      } else {
        setState(() => _pageTitle = 'Product not found');
      }
    } catch (e) {
      setState(() => _pageTitle = 'Error loading product');
      print('Error loading product: $e');
    }
  }

  // Save the product using MarketController
  Future<void> _saveProduct() async {
    final title = _nameController.text;
    final description = _descriptionController.text;
    final double price = double.tryParse(_priceController.text) ?? 0.00;

    // Validate the inputs
    if (title.isEmpty || description.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields with valid data')),
      );
      return;
    }

    if (widget.marketId == null) {
      // Add new product using MarketController
      await MarketController().createMarket(title, description, price);
    } else {
      // Update existing product using MarketController
      await MarketController().updateMarket(widget.marketId!, title, description, price);
    }

    Navigator.pop(context);
  }

  // Delete the product using MarketController
  Future<void> _deleteProduct() async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this product? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await MarketController().deleteMarket(widget.marketId!);
        Navigator.pop(context);
      } catch (e) {
        print("Error deleting product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting product")),
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

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: _pageTitle,
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: 'RM ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: _onPriceChanged,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.marketId == null ? 'Add Product' : 'Save'),
                  ),
                ),
                if (widget.marketId != null)
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _deleteProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      currentIndex: 2,
    );
  }
}
