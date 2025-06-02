import 'package:flutter/material.dart';
import 'package:ridemate/Mechanic/Work/workController.dart';
import 'package:ridemate/Template/masterScaffold.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WorkDetail extends StatefulWidget {
  final String shiftId;

  const WorkDetail({super.key, required this.shiftId});

  @override
  _WorkDetailState createState() => _WorkDetailState();
}

class _WorkDetailState extends State<WorkDetail> {
  final WorkController _controller = WorkController();
  bool _isLoading = true;
  Map<String, dynamic> shift = {};
  double _currentSliderValue = 2.5;

  @override
  void initState() {
    super.initState();
    _controller.initAssignData();
    _fetchShiftDetails();
  }

  Future<void> _fetchShiftDetails() async {
    try {
      Map<String, dynamic> shiftDetails = await _controller.fetchShiftDetails(widget.shiftId);
      setState(() {
        shift = shiftDetails;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching shift details: $e");
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: ${value ?? '-'}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Colors.amber, size: 20)),
        if (hasHalfStar) const Icon(Icons.star_half, color: Colors.amber, size: 20),
        ...List.generate(emptyStars, (_) => const Icon(Icons.star_border, color: Colors.amber, size: 20)),
      ],
    );
  }

  Future<void> _showRatingDialog(Map<String, dynamic> shift) async {
    _controller.currentSliderValue = 2.5; // default middle

    double tempRating = _controller.currentSliderValue;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rate Workshop"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select a rating", style: TextStyle(fontSize: 20)),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: tempRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        tempRating = value;
                      });
                    },
                  ),
                  Text(
                    'Rating: ${tempRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.rateWorkshop(
                  shift['Workshop ID'],
                  widget.shiftId,
                  tempRating,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thank you for rating!")),
                );
                _fetchShiftDetails(); // Refresh UI after rating
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

//   Future<void> _generateAndPrintReceipt(Map<String, dynamic> shift) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Padding(
//             padding: const pw.EdgeInsets.all(32.0), // a bit more padding for breathing space
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "RideMate Shift Receipt",
//                   style: pw.TextStyle(
//                     fontSize: 32,  // bigger title font
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 32), // bigger gap after title
//
//                 _buildLabelValueText("Transaction Number", shift['Transaction ID']),
//                 _buildLabelValueText("Workshop", shift['Workshop Name']),
//                 _buildLabelValueText("Contact", shift['Contact']),
//                 _buildLabelValueText("Mechanic's Name", shift['Mechanic Name']),
//                 _buildLabelValueText("Date", shift['Date']),
//                 _buildLabelValueText("Shift Time", "${shift['Start']} - ${shift['End']}"),
//                 _buildLabelValueText("Hourly Rate", "RM${(shift['Rate'] ?? 0.0).toStringAsFixed(2)}"),
//                 _buildLabelValueText("Salary", "RM${(shift['Salary'] ?? 0.0).toStringAsFixed(2)}"),
//                 _buildLabelValueText("Payment Date", shift['Payment Date']),
//
//                 pw.SizedBox(height: 40),
//                 pw.Divider(),
//
//                 pw.SizedBox(height: 16),
//                 pw.Text(
//                   "Thank you for your hard work!",
//                   style: pw.TextStyle(
//                     fontSize: 18,
//                     fontStyle: pw.FontStyle.italic,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//
//     await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
//   }
//
// // Helper widget for label + value rows with bigger font
//   pw.Widget _buildLabelValueText(String label, dynamic value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 14.0), // space between lines
//       child: pw.Row(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Expanded(
//             flex: 3,
//             child: pw.Text(
//               "$label:",
//               style: pw.TextStyle(
//                 fontSize: 18,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//           ),
//           pw.Expanded(
//             flex: 5,
//             child: pw.Text(
//               value?.toString() ?? '-',
//               style: pw.TextStyle(fontSize: 18),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterScaffold(
        customBarTitle: "Work Detail",
        leftCustomBarAction: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift['Workshop Name'] ?? 'Workshop',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.timer, "Operating Hours", shift['Operating Hours']),
                    _buildInfoRow(Icons.call, "Contact", shift['Contact']),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.blue),
                          const SizedBox(width: 10),
                          const Text("Rating: ", style: TextStyle(fontSize: 14)),
                          Text(
                            "${(shift['Rating'] ?? 0.0).toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          _buildStarRating((shift['Rating'] ?? 0.0).toDouble()),
                        ],
                      ),
                    ),
                    const Divider(height: 32, thickness: 1),
                    Text(
                      shift['Status'] ?? 'Status',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, "Date", shift['Date']),
                    _buildInfoRow(Icons.timer, "Shift", "${shift['Start']} - ${shift['End']}"),
                    _buildInfoRow(Icons.attach_money, "Rate", "RM${(shift['Rate'] ?? 0.0).toStringAsFixed(2)} / Hour"),
                    _buildInfoRow(Icons.attach_money, "Salary", "RM${(shift['Salary'] ?? 0.0).toStringAsFixed(2)}"),
                    if ((shift['Status'] == 'Completed' || shift['Status'] == 'Done') && shift["Mechanic's Rate"] != 0.0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.blue),
                            const SizedBox(width: 10),
                            const Text("Mechanic's Rate: ", style: TextStyle(fontSize: 14)),
                            Text(
                              "${(shift["Mechanic's Rate"] ?? 0.0).toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            _buildStarRating((shift["Mechanic's Rate"] ?? 0.0).toDouble()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if ((shift['Status'] == 'Completed') && shift["Workshop's Rate"] == 0.0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _showRatingDialog(shift);
                        },
                        icon: const Icon(Icons.star),
                        label: const Text("Rate"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (shift['Status'] == 'Completed' || shift['Status'] == 'Done')
                    SizedBox(
                      width: double.infinity,
                      child:
                      ElevatedButton.icon(
                        onPressed: () async {
                          final shiftDetails = await _controller.fetchShiftDetails(widget.shiftId);
                          await _controller.generateAndPrintReceipt(shiftDetails);
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text("Print Receipt"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),


                    ),
                ],
              ),
            ),

          ],
        ),
        currentIndex: 2,
      ),
    );
  }
}
