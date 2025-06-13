import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class DetailShift extends StatefulWidget {
  final String? shiftId;

  const DetailShift({super.key, this.shiftId});

  @override
  _DetailShiftState createState() => _DetailShiftState();
}

class _DetailShiftState extends State<DetailShift> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _totalVacancyController = TextEditingController();
  final TextEditingController _jobScopeController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  String _selectedDay = 'Monday';
  String _pageTitle = 'Add Shift';

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.shiftId != null) {
      _loadShiftDetails();
    }
  }

  Future<void> _loadShiftDetails() async {
    if (widget.shiftId == null) return;

    try {
      Map<String, dynamic>? shift = await InventoryController().getShiftById(widget.shiftId!);
      if (shift != null) {
        setState(() {
          _selectedDay = shift['Day'] ?? 'Monday';
          _dateController.text = shift['Date'] ?? '';
          _startTimeController.text = shift['Start'] ?? '';
          _endTimeController.text = shift['End'] ?? '';
          _rateController.text = (shift['Rate'] ?? 0.0).toString();
          _totalVacancyController.text = (shift['Vacancy'] ?? 0).toString();
          _jobScopeController.text = shift['Scope'] ?? '';
          _pageTitle = 'Edit Shift';
        });
      } else {
        setState(() => _pageTitle = 'Shift not found');
      }
    } catch (e) {
      setState(() => _pageTitle = 'Error loading shift');
      print('Error loading shift: $e');
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      String weekday = DateFormat('EEEE').format(pickedDate); // Get full day name

      setState(() {
        _dateController.text = formattedDate;
        _selectedDay = weekday;
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      String formattedTime = pickedTime.format(context);
      if (isStartTime) {
        _startTimeController.text = formattedTime;
      } else {
        _endTimeController.text = formattedTime;
      }
    }
  }

  Future<void> _saveShift() async {
    final date = _dateController.text.trim();
    final rateText = _rateController.text.trim();
    final vacancyText = _totalVacancyController.text.trim();
    final jobScope = _jobScopeController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (date.isEmpty ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        rateText.isEmpty ||
        vacancyText.isEmpty ||
        jobScope.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields before saving.')),
      );
      return;
    }

    final double? rate = double.tryParse(rateText);
    if (rate == null || rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive rate.')),
      );
      return;
    }

    final int? totalVacancy = int.tryParse(vacancyText);
    if (totalVacancy == null || totalVacancy <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number for total vacancies.')),
      );
      return;
    }

    final double formattedRate = double.parse(rate.toStringAsFixed(2));

    try {
      if (widget.shiftId == null) {
        await InventoryController().addShift(_selectedDay, date, startTime, endTime, totalVacancy, formattedRate, jobScope);
      } else {
        await InventoryController().updateShift(widget.shiftId!, _selectedDay, date, startTime, endTime, totalVacancy, formattedRate, jobScope);
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error saving shift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save shift.')),
      );
    }
  }

  Future<void> _deleteShift() async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this shift? This action cannot be undone."),
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
        await InventoryController().deleteShift(widget.shiftId!);
        Navigator.pop(context);
      } catch (e) {
        print("Error deleting shift: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting shift")),
        );
      }
    }
  }

  // Restrict input to numeric only (int or double)
  void _onRateChanged(String value) {
    if (value.isNotEmpty && double.tryParse(value) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number for salary rate")),
      );
    }
  }

  void _onVacancyChanged(String value) {
    if (value.isNotEmpty && int.tryParse(value) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number for vacancy")),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: _daysOfWeek.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: null, // disable manual selection
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _startTimeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _pickTime(true),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _endTimeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _pickTime(false),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        labelText: 'Rate per Hour',
                        prefixText: 'RM ',
                        suffixText: ' / Hour',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onRateChanged,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _totalVacancyController,
                      decoration: InputDecoration(
                        labelText: 'Total Vacancies',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onVacancyChanged,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _jobScopeController,
                      decoration: InputDecoration(
                        labelText: 'Job Scope',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: _saveShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.shiftId == null ? 'Add Shift' : 'Save'),
                  ),
                ),
                if (widget.shiftId != null)
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _deleteShift,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete Shift'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      currentIndex: 1,
    );
  }
}
