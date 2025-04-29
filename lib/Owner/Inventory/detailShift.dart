import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridemate/Owner/Inventory/inventoryController.dart';

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
      _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
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
    final date = _dateController.text;
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final int totalVacancy = int.tryParse(_totalVacancyController.text) ?? 0;
    final jobScope = _jobScopeController.text;
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;

    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    // Ensure rate is formatted to 2 decimal places
    final double formattedRate = double.parse(rate.toStringAsFixed(2));

    if (widget.shiftId == null) {
      await InventoryController().addShift(_selectedDay, date, startTime, endTime, totalVacancy, formattedRate, jobScope);
    } else {
      await InventoryController().updateShift(widget.shiftId!, _selectedDay, date, startTime, endTime, totalVacancy, formattedRate, jobScope);
    }

    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          if (widget.shiftId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteShift,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(labelText: 'Day'),
              items: _daysOfWeek.map((day) {
                return DropdownMenuItem(value: day, child: Text(day));
              }).toList(),
              onChanged: (value) => setState(() => _selectedDay = value!),
            ),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
            ),
            TextField(
              controller: _startTimeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Start Time',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(true),
                ),
              ),
            ),
            TextField(
              controller: _endTimeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'End Time',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(false),
                ),
              ),
            ),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Rate per Hour',
                prefixText: 'RM ',
                suffixText: ' / Hour',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _totalVacancyController,
              decoration: const InputDecoration(labelText: 'Total Vacancies'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _jobScopeController,
              decoration: const InputDecoration(labelText: 'Job Scope'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveShift,
              child: Text(widget.shiftId == null ? 'Add Shift' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}