import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.adminDashboard),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _dashboardData = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

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
            _buildStatCard(
                'Total Revenue', currencyFormat.format(_dashboardData?['totalRevenue'] ?? 0.0), Icons.monetization_on, Colors.green),
            _buildStatCard(
                'Total Orders', numberFormat.format(_dashboardData?['totalOrders'] ?? 0), Icons.receipt, Colors.blue),
            _buildStatCard(
                'Total Users', numberFormat.format(_dashboardData?['totalUsers'] ?? 0), Icons.people, Colors.orange),
            _buildStatCard(
                'Active Merchants', '${_dashboardData?['activeMerchants'] ?? 0}', Icons.store, Colors.purple),
          ],
        ),
      ],
    );
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
}
