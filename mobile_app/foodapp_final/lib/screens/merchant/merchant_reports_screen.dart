// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class MerchantReportsScreen extends StatefulWidget {
//   const MerchantReportsScreen({super.key});
//
//   @override
//   State<MerchantReportsScreen> createState() => _MerchantReportsScreenState();
// }
//
// class _MerchantReportsScreenState extends State<MerchantReportsScreen> {
//   DateTime _selectedDate = DateTime.now();
//   Map<String, dynamic>? _reportData;
//   bool _isLoading = false;
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _reportData = null; // Clear previous report
//       });
//     }
//   }
//
//   void _getDailyReport() {
//     // IMPLEMENTED: Fetches report for the selected date
//     // In a real app, call ApiConstants.merchantReportsDaily
//     setState(() => _isLoading = true);
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _reportData = {
//           'totalSales': 1234.50,
//           'totalOrders': 25,
//         };
//         _isLoading = false;
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sales Reports')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text('Report for: ${DateFormat.yMMMd().format(_selectedDate)}'),
//                 IconButton(
//                   icon: const Icon(Icons.calendar_today),
//                   onPressed: () => _selectDate(context),
//                 )
//               ],
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: _getDailyReport,
//                 icon: const Icon(Icons.assessment),
//                 label: const Text('Get Daily Report'),
//               ),
//             ),
//             const Divider(height: 32),
//             if (_isLoading) const CircularProgressIndicator(),
//             if (_reportData != null)
//               Card(
//                 child: ListTile(
//                   title: Text('Sales: Rs. ${_reportData!['totalSales']}'),
//                   subtitle: Text('Orders: ${_reportData!['totalOrders']}'),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/sales_report.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/sales_bar_chart.dart'; // FIX: Import the new chart widget
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MerchantReportsScreen extends StatefulWidget {
  const MerchantReportsScreen({super.key});

  @override
  State<MerchantReportsScreen> createState() => _MerchantReportsScreenState();
}

class _MerchantReportsScreenState extends State<MerchantReportsScreen> {
  final _storage = const FlutterSecureStorage();
  DateTimeRange? _selectedDateRange;
  SalesReport? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: now, end: now);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _reportData = null;
      });
    }
  }

  Future<void> _getReport() async {
    if (_selectedDateRange == null) {
      NotificationUtils.showAnimatedPopup(context, title: "Select a Date Range", message: "Please select a start and end date.", isSuccess: false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      final endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);

      final url = Uri.parse('${ApiConstants.baseUrl}/api/merchant/reports/sales?startDate=$startDate&endDate=$endDate');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _reportData = SalesReport.fromJson(jsonDecode(response.body));
          });
        } else {
          throw Exception('Failed to load report from server.');
        }
      }
    } catch (e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: e.toString(), isSuccess: false);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePdf(SalesReport report) async {
    final pdf = pw.Document();
    final start = DateFormat.yMMMd().format(report.startDate);
    final end = DateFormat.yMMMd().format(report.endDate);
    final dateRangeText = start == end ? start : '$start to $end';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Sales Report - $dateRangeText', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Header(level: 1, text: 'Summary'),
          pw.Bullet(text: 'Total Revenue: Rs. ${report.totalRevenue.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Total Successful Orders: ${report.totalOrders}'),
          pw.Bullet(text: 'Total Items Sold: ${report.totalItemsSold}'),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, text: 'Top Movers'),
          if(report.mostSoldItem != null) pw.Bullet(text: 'Most Sold Item: ${report.mostSoldItem!.itemName} (${report.mostSoldItem!.quantitySold} units)'),
          if(report.leastSoldItem != null) pw.Bullet(text: 'Least Sold Item: ${report.leastSoldItem!.itemName} (${report.leastSoldItem!.quantitySold} units)'),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, text: 'Item-wise Sales Breakdown'),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Item Name', 'Quantity Sold', 'Total Revenue (Rs.)'],
            data: report.itemSales.map((item) => [
              item.itemName,
              item.quantitySold.toString(),
              item.totalRevenue.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports'),
        actions: [
          if (_reportData != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _generatePdf(_reportData!),
              tooltip: 'Download as PDF',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getReport,
              icon: const Icon(Icons.assessment_outlined),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            const Divider(height: 32),
            Expanded(child: _buildReportView()),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final start = DateFormat.yMMMd().format(_selectedDateRange!.start);
    final end = DateFormat.yMMMd().format(_selectedDateRange!.end);
    final text = start == end ? 'For $start' : 'From $start to $end';

    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.indigo),
        title: const Text("Report Period"),
        subtitle: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.edit_calendar_outlined),
        onTap: () => _selectDateRange(context),
      ),
    );
  }

  Widget _buildReportView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_reportData == null) {
      return const Center(
          child: Text('Select a date range and click "Generate Report".',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          // FIX: Add the new Bar Chart widget to the view
          if (_reportData!.itemSales.isNotEmpty) ...[
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Top Selling Items (by Quantity)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            SalesBarChart(itemSales: _reportData!.itemSales),
            const SizedBox(height: 16),
          ],
          _buildTopSellersCard(),
          const SizedBox(height: 16),
          _buildAllItemsCard(),
        ],
      ),
    );
  }

  Card _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow('Total Revenue', 'Rs. ${_reportData!.totalRevenue.toStringAsFixed(2)}', Colors.green.shade700),
            _buildSummaryRow('Total Orders', _reportData!.totalOrders.toString(), Colors.blue.shade700),
            _buildSummaryRow('Total Items Sold', _reportData!.totalItemsSold.toString(), Colors.orange.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Card _buildTopSellersCard() {
    final mostSold = _reportData!.mostSoldItem;
    final leastSold = _reportData!.leastSoldItem;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Movers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (mostSold != null) ListTile(
              leading: const Icon(Icons.arrow_circle_up, color: Colors.green),
              title: const Text('Most Sold Item'),
              subtitle: Text('${mostSold.itemName} (${mostSold.quantitySold} units)'),
            ),
            if (leastSold != null && mostSold?.menuItemId != leastSold.menuItemId) ListTile(
              leading: const Icon(Icons.arrow_circle_down, color: Colors.red),
              title: const Text('Least Sold Item'),
              subtitle: Text('${leastSold.itemName} (${leastSold.quantitySold} units)'),
            ),
            if(mostSold == null) const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No items were sold in this period.'),
            )),
          ],
        ),
      ),
    );
  }

  Card _buildAllItemsCard() {
    if (_reportData!.itemSales.isEmpty) return const Card();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Item-wise Sales Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Qty Sold'), numeric: true),
                  DataColumn(label: Text('Revenue'), numeric: true),
                ],
                rows: _reportData!.itemSales.map((itemSale) => DataRow(
                  cells: [
                    DataCell(Text(itemSale.itemName)),
                    DataCell(Text(itemSale.quantitySold.toString())),
                    DataCell(Text('Rs. ${itemSale.totalRevenue.toStringAsFixed(2)}')),
                  ],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}