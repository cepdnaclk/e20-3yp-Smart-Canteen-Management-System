import 'dart:async'; // Import the async library for Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/screens/merchant/manage_menu_screen.dart';
import 'package:food_app/screens/merchant/merchant_profile_screen.dart';
import 'package:food_app/screens/merchant/merchant_reports_screen.dart';
import 'package:food_app/screens/merchant/order_management_screen.dart';
import 'package:food_app/screens/merchant/top_up_requests_screen.dart';
import 'package:food_app/widgets/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  final _storage = const FlutterSecureStorage();
  String _merchantName = 'Merchant';
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  Timer? _refreshTimer; // Timer for auto-refreshing

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // **FIX:** Changed timer to 15 seconds for more frequent updates.
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      if (mounted) {
        _fetchDashboardData(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // **FIX:** Always cancel the timer to prevent memory leaks
    super.dispose();
  }

  // Fetches all necessary data for the screen
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchMerchantName(),
      _fetchDashboardData(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // Fetches just the dashboard stats, with an option to control the loading indicator
  Future<void> _fetchDashboardData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final token = await _storage.read(key: 'jwt_token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final revenueUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.merchantReportsDaily}?date=$today');
      final revenueResponse = await http.get(revenueUri, headers: headers);

      final pendingOrdersUri = Uri.parse(ApiConstants.baseUrl + ApiConstants.merchantOrdersPending);
      final pendingOrdersResponse = await http.get(pendingOrdersUri, headers: headers);

      double dailyRevenue = 0.0;
      if (revenueResponse.statusCode == 200) {
        final data = jsonDecode(revenueResponse.body);
        dailyRevenue = (data['totalSales'] as num?)?.toDouble() ?? 0.0;
      }

      int newOrderCount = 0;
      if (pendingOrdersResponse.statusCode == 200) {
        newOrderCount = (jsonDecode(pendingOrdersResponse.body) as List).length;
      }

      if (mounted) {
        setState(() {
          _dashboardData = {
            'dailyRevenue': dailyRevenue,
            'newOrderCount': newOrderCount,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardData = {'dailyRevenue': 0.0, 'newOrderCount': 0};
        });
      }
    } finally {
      if (showLoading && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMerchantName() async {
    final name = await _storage.read(key: 'user_name');
    if (mounted && name != null) {
      setState(() => _merchantName = name);
    }
  }

  void _navigateAndRefresh(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      _fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () => _navigateAndRefresh(const MerchantProfileScreen()),
          )
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: _isLoading ? _buildShimmer() : _buildDashboard(),
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildWelcomeHeader(),
        const SizedBox(height: 24),
        _buildStatsCards(),
        const SizedBox(height: 24),
        _buildActionsGrid(),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Text(
      'Welcome Back, $_merchantName',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsCards() {
    final revenue = _dashboardData?['dailyRevenue'] ?? 0.0;
    final newOrders = _dashboardData?['newOrderCount'] ?? 0;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    return Row(
      children: [
        Expanded(child: _buildStatCard("Today's Revenue", currencyFormat.format(revenue), Icons.trending_up, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('New Orders', newOrders.toString(), Icons.notifications, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard('Order Management', Icons.receipt_long, Colors.blue, () {
          _navigateAndRefresh(const OrderManagementScreen());
        }),
        _buildActionCard('Manage Menu', Icons.restaurant_menu, Colors.red, () {
          _navigateAndRefresh(const ManageMenuScreen());
        }),
        _buildActionCard('Top-Up Requests', Icons.monetization_on, Colors.purple, () {
          _navigateAndRefresh(const TopUpRequestsScreen());
        }),
        _buildActionCard('Sales Reports', Icons.bar_chart, Colors.teal, () {
          _navigateAndRefresh(const MerchantReportsScreen());
        }),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 2,
        color: color.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: HSLColor.fromColor(color).withLightness(0.2).toColor()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 200,
            height: 30.0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 24),
          ),
        ),
        Row(
          children: [
            Expanded(child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Card(child: SizedBox(height: 120)))),
            const SizedBox(width: 16),
            Expanded(child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Card(child: SizedBox(height: 120)))),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: List.generate(4, (index) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Card())),
        ),
      ],
    );
  }
}
