import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _generateReport() {
    // In a real app, call your API with _startDate and _endDate
    // using ApiConstants.adminReportsSalesOverview
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _reportData = {
          'totalSales': 45800.50,
          'totalOrders': 152,
          'popularItem': 'Chicken Fried Rice',
        };
        _isLoading = false;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.assessment),
                label: const Text('Generate Report'),
              ),
            ),
            const Divider(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : _reportData == null
                ? const Text('Select a date range and generate a report.')
                : _buildReportDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text('Start Date'),
              TextButton(
                onPressed: () => _selectDate(context, isStartDate: true),
                child: Text(DateFormat.yMMMd().format(_startDate)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text('End Date'),
              TextButton(
                onPressed: () => _selectDate(context, isStartDate: false),
                child: Text(DateFormat.yMMMd().format(_endDate)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportDisplay() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report from ${DateFormat.yMMMd().format(_startDate)} to ${DateFormat.yMMMd().format(_endDate)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 30),
            _buildReportRow('Total Sales:', 'Rs. ${_reportData!['totalSales']}'),
            _buildReportRow('Total Orders:', '${_reportData!['totalOrders']}'),
            _buildReportRow('Most Popular Item:', '${_reportData!['popularItem']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}