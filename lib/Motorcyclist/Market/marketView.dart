import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ridemate/Motorcyclist/Market/marketController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class MarketView extends StatefulWidget {
  final String marketId;
  final bool isOwner;

  const MarketView({super.key, required this.marketId, required this.isOwner});

  @override
  _MarketViewState createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      Map<String, dynamic>? product = await MarketController().getMarketProductById(widget.marketId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading product: $e');
    }
  }

  Widget _buildProductImage() {
    final String? base64String = _product?['Image'];

    if (base64String == null || base64String.isEmpty) {
      return const Icon(Icons.broken_image, size: 150);
    }

    try {
      Uint8List bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 150);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return const Scaffold(
        body: Center(child: Text('Product not found')),
      );
    }

    return MasterScaffold(
      customBarTitle: _product!['Name'] ?? 'Market Product',
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), // leave space for button
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProductImage(),
                  const SizedBox(height: 16),
                  Text(
                    _product!['Name'] ?? 'Unnamed Product',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!['Description'] ?? 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Price: RM ${_product!['Price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chat/detail',
                  arguments: {'otherUserId': _product!['Owner']},
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Chat with Seller',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      currentIndex: 2,
    );
  }
}
