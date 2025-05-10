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

  // Load product details from the MarketController
  Future<void> _loadProductDetails() async {
    try {
      // Fetch product details using the MarketController
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

  // Navigate to the chat screen for this product's owner
  void _startChat() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ChatScreen(
    //       recipientId: _product?['ownerId'],  // Assuming 'ownerId' is the field for the owner's user ID
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        body: const Center(child: Text('Product not found')),
      );
    }

    return MasterScaffold(
      customBarTitle: _product!['Name'] ?? 'Market Product',
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _product!['Name'] ?? 'Unnamed Product',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _product!['Description'] ?? 'No description available.',
              style: Theme.of(context).textTheme.bodyMedium,
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chat/detail',
                  arguments: {'otherUserId': _product!['Owner']}, // Pass the userId of the seller
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Chat with Seller'),
            ),

          ],
        ),
      ),
      currentIndex: 2,
    );
  }
}
