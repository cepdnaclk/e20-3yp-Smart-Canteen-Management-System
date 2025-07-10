import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<dynamic> _itemSales = [];

  final _storage = const FlutterSecureStorage();

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

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    _reportData = null; // Clear previous report

    try {
      final token = await _storage.read(key: 'jwt_token');
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);

      final uri = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminReportsSalesOverview}?startDate=$formattedStartDate&endDate=$formattedEndDate');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _reportData = jsonDecode(response.body);
            _itemSales = _reportData?['itemSales'] ?? [];
          });
        } else {
          // Show error message
        }
      }
    } catch (e) {
      // Show error
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: _isLoading ? Container() : const Icon(Icons.assessment),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Generate Report'),
              ),
            ),
            const Divider(height: 40),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const CircularProgressIndicator();
    if (_reportData == null) return const Text('Select a date range and generate a report.', textAlign: TextAlign.center);
    if (_itemSales.isEmpty) return const Text('No sales data found for the selected period.', textAlign: TextAlign.center);

    return _buildReportDisplay();
  }

  Widget _buildReportDisplay() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    // For Pie Chart
    final top5Items = _itemSales.take(5).toList();
    final List<Color> pieColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Report from ${DateFormat.yMMMd().format(_startDate)} to ${DateFormat.yMMMd().format(_endDate)}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // --- Summary Cards ---
        Row(
          children: [
            Expanded(child: _summaryCard("Total Revenue", currencyFormat.format(_reportData!['totalRevenue']), Icons.monetization_on)),
            const SizedBox(width: 16),
            Expanded(child: _summaryCard("Total Orders", _reportData!['totalOrders'].toString(), Icons.receipt)),
          ],
        ),
        const SizedBox(height: 24),
        // --- Pie Chart ---
        Text("Top 5 Sold Items (by Revenue)", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: List.generate(top5Items.length, (i) {
                final item = top5Items[i];
                return PieChartSectionData(
                  color: pieColors[i % pieColors.length],
                  value: (item['totalRevenue'] as num).toDouble(),
                  title: '${item['itemName']}\n(${currencyFormat.format(item['totalRevenue'])})',
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const Divider(height: 40),
        // --- Full Item List ---
        Text("Complete Sales Data", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _itemSales.length,
          itemBuilder: (context, index) {
            final item = _itemSales[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text((index + 1).toString())),
                title: Text(item['itemName']),
                subtitle: Text('Sold: ${item['quantitySold']}'),
                trailing: Text(currencyFormat.format(item['totalRevenue']), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

// Omitted: _buildDateRangeSelector (it is good as it is)


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
}