import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/Motorcyclist/Market/detailMarket.dart';
import 'package:ridemate/Motorcyclist/Market/marketController.dart';
import 'package:ridemate/Motorcyclist/Market/marketView.dart';
import 'package:ridemate/Template/masterScaffold.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


class Market extends StatefulWidget {
  const Market({super.key});

  @override
  State<Market> createState() => _MarketState();
}

class _MarketState extends State<Market> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _marketProducts = [];
  bool _isLoading = true;
  bool _isControllerReady = false;
  final Distance _distance = const Distance();
  LatLng? _userLocation;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _isControllerReady = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _userLocation = LatLng(position.latitude, position.longitude);
      _fetchProducts();
    });

  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>>? products;

    if (_tabController.index == 0) {
      // For "Market" tab, fetch all market products (excluding the current user)
      products = await MarketController().getAllMarketProducts();
    } else {
      // For "My Market" tab, fetch products owned by the current user
      products = await MarketController().getOwnedMarketProducts();
    }

    // Compute distance if location is available
    if (_userLocation != null && products != null) {
      for (var product in products) {
        if (product.containsKey('Latitude') && product.containsKey('Longitude')) {
          final double lat = double.tryParse(product['Latitude'].toString()) ?? 0.0;
          final double lng = double.tryParse(product['Longitude'].toString()) ?? 0.0;
          final productLocation = LatLng(lat, lng);

          final km = _distance.as(LengthUnit.Kilometer, _userLocation!, productLocation);
          product['Distance'] = km;
        }
      }

      // Sort by distance if desired
      products.sort((a, b) {
        final da = a['Distance'] ?? double.infinity;
        final db = b['Distance'] ?? double.infinity;
        return da.compareTo(db);
      });
    }

    setState(() {
      _marketProducts = products ?? [];
      _isLoading = false;
    });
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final base64String = product['Image'] ?? '';
    Widget imageWidget;

    if (base64String.isNotEmpty) {
      try {
        Uint8List imageBytes = base64Decode(base64String);
        imageWidget = Container(
          height: 120,
          alignment: Alignment.center,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
          ),
        );

      } catch (e) {
        // In case of decoding error, fallback to broken image icon
        imageWidget = const Icon(Icons.broken_image);
      }
    } else {
      // No image data, show placeholder icon
      imageWidget = const Icon(Icons.image_not_supported);
    }

    return GestureDetector(
      onTap: () {
        if (_tabController.index == 0) {
          Navigator.pushNamed(
            context,
            '/market/view',
            arguments: {
              'marketId': product['id'],
              'isOwner': false,
            },
          ).then((_) => _fetchProducts());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketDetail(
                marketId: product['id'],
              ),
            ),
          ).then((_) => _fetchProducts());
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
                const SizedBox(height: 8),
                Text(
                  product['Name'] ?? 'Unnamed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  product['Description'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "RM ${product['Price']?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 6),
                if (product.containsKey('Distance'))
                  Text(
                    "${product['Distance'].toStringAsFixed(2)} KM away",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return MasterScaffold(
      customBarTitle: "Market",
      rightCustomBarAction: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/market/detail',
            arguments: {},
          ).then((_) => _fetchProducts()); // Refresh on return
        },

      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Market"),
              Tab(text: "My Market"),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _marketProducts.isEmpty
                ? const Center(child: Text("No products found."))
                : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: _marketProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2 / 3,
                ),
                itemBuilder: (context, index) =>
                    _buildProductCard(_marketProducts[index]),
              ),
            ),
          ),
        ],
      ),
      currentIndex: 2,
    );
  }
}
