import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _storage = const FlutterSecureStorage();
  Timer? _timer;

  // State variables
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardStats;
  List<FlSpot> _salesChartData = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    // Auto-refresh data every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchDashboardData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Important to prevent memory leaks
    super.dispose();
  }

  Future<void> _fetchDashboardData({bool isRefresh = false}) async {
    if (!mounted) return;
    if (!isRefresh) {
      setState(() => _isLoading = true);
    }

    try {
      final token = await _storage.read(key: 'jwt_token');
      final headers = {'Authorization': 'Bearer $token'};

      // Fetch stats and chart data in parallel
      final statsFuture = http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.adminDashboard), headers: headers);
      final chartFuture = http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.adminDashboardSalesChart), headers: headers);

      final responses = await Future.wait([statsFuture, chartFuture]);

      if (mounted) {
        if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
          final stats = jsonDecode(responses[0].body);
          final chartData = jsonDecode(responses[1].body) as Map<String, dynamic>;

          // Process chart data
          final processedChartData = chartData.entries.map((entry) {
            final date = DateTime.parse(entry.key);
            final value = (entry.value as num).toDouble();
            // Use day of the month as X-axis value
            return FlSpot(date.day.toDouble(), value);
          }).toList();

          setState(() {
            _dashboardStats = stats;
            _salesChartData = processedChartData;
          });
        } else {
          // Handle error gracefully
        }
      }
    } catch (e) {
      // Handle exceptions like no internet connection
    } finally {
      if (mounted && !isRefresh) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: _isLoading ? _buildShimmer() : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final numberFormat = NumberFormat.compact();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Total Revenue', currencyFormat.format(_dashboardStats?['totalRevenue'] ?? 0.0), Icons.monetization_on, Colors.green),
            _buildStatCard('Total Orders', numberFormat.format(_dashboardStats?['totalOrders'] ?? 0), Icons.receipt, Colors.blue),
            _buildStatCard('Total Users', numberFormat.format(_dashboardStats?['totalUsers'] ?? 0), Icons.people, Colors.orange),
            _buildStatCard('Active Merchants', '${_dashboardStats?['activeMerchants'] ?? 0}', Icons.store, Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        Text("Last 30 Days' Sales Trend", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildSalesChart(),
      ],
    );
  }

  Widget _buildSalesChart() {
    return SizedBox(
      height: 200,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, reservedSize: 30)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _salesChartData,
                  isCurved: true,
                  color: Colors.deepPurple,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.deepPurple.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: List.generate(4, (_) => Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
      ),
    );
  }
