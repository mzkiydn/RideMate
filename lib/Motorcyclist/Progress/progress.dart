import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridemate/Motorcyclist/Progress/progressController.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Progress extends StatelessWidget {
  const Progress({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProgressController(), // Providing ProgressController
      child: Consumer<ProgressController>(
        builder: (context, progressController, child) {
          return MasterScaffold(
            customBarTitle: "Progress",

            body: Column(
              children: [
                // Workshop info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column for logo and rating
                      Column(
                        children: [
                          // Logo
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage(progressController.workshopInfo['logo']),
                          ),
                          const SizedBox(height: 8),
                          // Rating
                          Row(
                            children: List.generate(5, (index) {
                              if (index < progressController.workshopInfo['rating']) {
                                return Icon(Icons.star, color: Colors.amber, size: 16);
                              } else {
                                return Icon(Icons.star_border, color: Colors.amber, size: 16);
                              }
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16), // Space between columns

                      // Column for address, operating hours, and contact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Workshop name
                            Text(
                              progressController.workshopInfo['name'],
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            // Address
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  progressController.workshopInfo['address'],
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Contact
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.phone),
                                    SizedBox(width: 8),
                                    Text(
                                      progressController.workshopInfo['contact'],
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                // ElevatedButton(
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) => const Personal(),
                                //       ), // Should open chat with workshop
                                //     );
                                //   },
                                //   child: const Text("Contact"),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Receipt Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Number and Date-Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Receipt #: ${progressController.receiptInfo['receiptNumber']}",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            progressController.receiptInfo['dateTime'],
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Mechanic's Details
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            "Mechanic: ${progressController.receiptInfo['mechanicName']}",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Icon(Icons.phone, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            progressController.receiptInfo['mechanicContact'],
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Product/Service Details
                      Text(
                        "Service: ${progressController.receiptInfo['service']}",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Product: ${progressController.receiptInfo['product']}",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 10),

                      // Payment Status and Verify Completion Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Payment Status: ${progressController.receiptInfo['paymentStatus']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              progressController.verifyCompletion();
                            },
                            child: const Text("Verify Completion"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            currentIndex: 2,
          );
        },
      ),
    );
  }
}
