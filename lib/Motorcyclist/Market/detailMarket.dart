import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  String _pageTitle = 'Add Product';
  File? _selectedImage;
  String? _image;


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
          _image = product['Image'];
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

    final error = validateMarketItem(
      title: _nameController.text,
      price: _priceController.text,
      description: _descriptionController.text,
      hasImage: _image != null, // or existingImages.isNotEmpty
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return; // Stop submit
    }

    String? base64Image;

    if (_selectedImage != null) {
      // Convert selected image file to base64 string without opening picker again
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    if (widget.marketId == null) {
      // Creating new product
      await MarketController().createMarket(
        _nameController.text,
        _descriptionController.text,
        double.parse(_priceController.text),
        base64Image: base64Image,
      );
    } else {
      // Updating existing product
      await MarketController().updateMarket(
        widget.marketId!,
        _nameController.text,
        _descriptionController.text,
        double.parse(_priceController.text),
        base64Image: base64Image, // null if no new image selected, no image update
      );
    }
    Navigator.pop(context);
  }

  String? validateMarketItem({required String title, required String price, required String description, required bool hasImage}) {
    if (title.trim().isEmpty || title.length < 3) {
      return 'Name must be at least 3 characters long.';
    }

    if (price.trim().isEmpty) return 'Price is required.';
    final parsedPrice = double.tryParse(price);
    if (parsedPrice == null || parsedPrice <= 0) {
      return 'Enter a valid price greater than 0.';
    }

    if (description.trim().isEmpty || description.length < 10) {
      return 'Description must be at least 10 characters long.';
    }

    if (!hasImage) {
      return 'Please upload at least one image.';
    }

    return null; // no error
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      try {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImage = File(pickedFile.path); // ✅ Add this line
          _image = base64String;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading image: $e')),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImage != null
                              ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 180,
                          )
                              : (_image != null && _image!.isNotEmpty)
                              ? Image.memory(
                            base64Decode(_image!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 180,
                          )
                              : const Text('Tap to select an image'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(widget.marketId == null ? 'Add Product' : 'Save'),
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.marketId != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
