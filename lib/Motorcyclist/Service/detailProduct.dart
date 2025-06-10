import 'package:flutter/material.dart';
import 'package:ridemate/Motorcyclist/Service/serviceController.dart';
import 'package:ridemate/Motorcyclist/Service/detailService.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class DetailProduct extends StatefulWidget {
  final String customBarTitle;
  final String workshopId;

  DetailProduct({super.key, required this.customBarTitle, required this.workshopId});

  @override
  _DetailProductState createState() => _DetailProductState();
}

class _DetailProductState extends State<DetailProduct> {
  final ServiceController serviceController = ServiceController();
  Map<String, dynamic>? workshop;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  double rating = 0.0;
  int fullStars = 0;
  bool hasHalfStar = false;


  @override
  void initState() {
    super.initState();
    fetchWorkshop();
    fetchProducts();
  }

  Future<void> fetchWorkshop() async {
    List<Map<String, dynamic>> workshops = await serviceController.getWorkshops();
    setState(() {
      workshop = workshops.firstWhere(
            (item) => item['Name'] == widget.customBarTitle,
        orElse: () => {
          'Name': widget.customBarTitle,
          // 'address': 'No address available',
          'Operating Hours': 'N/A',
          'Contact': 'N/A',
          'Rating': '0.0',
          'Longitude': '0.0',
          'Latitude': '0.0',
        },
      );
      rating = (workshop!['Rating'] ?? 0).toDouble();
      fullStars = rating.floor();
      hasHalfStar = rating - fullStars >= 0.5;
      isLoading = false;
    });
  }

  Future<void> fetchProducts() async {
    try {
      List<Map<String, dynamic>> fetchedProducts = await serviceController.fetchProducts(widget.workshopId);
      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print("Error fetching products: $e");
      setState(() {
        products = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MasterScaffold(
        customBarTitle: widget.customBarTitle,
        leftCustomBarAction: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Workshop Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time_sharp, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              workshop?['Operating Hours'] ?? 'N/A',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              workshop?['Contact'] ?? 'N/A',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "${rating.toStringAsFixed(1)}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Colors.amber, size: 20)),
                            if (hasHalfStar) const Icon(Icons.star_half, color: Colors.amber, size: 20),
                            ...List.generate(5 - fullStars - (hasHalfStar ? 1 : 0),
                                    (_) => const Icon(Icons.star_border, color: Colors.amber, size: 20)),
                            const SizedBox(width: 8),

                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TabBar
            TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: "Product"),
                Tab(text: "Service"),
              ],
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  // Product List
                  products.isEmpty
                      ? Center(child: Text("No products available"))
                      : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name (Title)
                                Text(
                                  product['Name'] ?? 'No name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Info Row: Motorcycle, Quantity, Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Motorcycle: ${product['Motorcycle'] ?? 'N/A'}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      "Qty: ${product['Stock'] ?? 'N/A'}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      "RM ${product['Price']?.toStringAsFixed(2) ?? 'N/A'}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Service Tab
                  DetailService(customBarTitle: widget.customBarTitle, workshopId: widget.workshopId),
                ],
              ),
            )

          ],
        ),
        currentIndex: 1,
      ),
    );
  }
}
