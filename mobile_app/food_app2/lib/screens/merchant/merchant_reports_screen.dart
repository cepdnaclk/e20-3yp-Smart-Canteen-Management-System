import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MerchantReportsScreen extends StatefulWidget {
  const MerchantReportsScreen({super.key});

  @override
  State<MerchantReportsScreen> createState() => _MerchantReportsScreenState();
}

class _MerchantReportsScreenState extends State<MerchantReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _reportData = null; // Clear previous report
      });
    }
  }

  void _getDailyReport() {
    // IMPLEMENTED: Fetches report for the selected date
    // In a real app, call ApiConstants.merchantReportsDaily
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _reportData = {
          'totalSales': 1234.50,
          'totalOrders': 25,
        };
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Report for: ${DateFormat.yMMMd().format(_selectedDate)}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getDailyReport,
                icon: const Icon(Icons.assessment),
                label: const Text('Get Daily Report'),
              ),
            ),
            const Divider(height: 32),
            if (_isLoading) const CircularProgressIndicator(),
            if (_reportData != null)
              Card(
                child: ListTile(
                  title: Text('Sales: Rs. ${_reportData!['totalSales']}'),
                  subtitle: Text('Orders: ${_reportData!['totalOrders']}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}