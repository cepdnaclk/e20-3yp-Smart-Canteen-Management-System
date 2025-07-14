import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/admin/user_management_screen.dart';
import 'package:food_app/screens/admin/merchant_management_screen.dart';
import 'package:food_app/screens/admin/menu_order_monitoring_screen.dart';
import 'package:food_app/screens/admin/admin_reports_screen.dart';
import 'package:food_app/screens/admin/financial_control_screen.dart';
import 'package:food_app/screens/admin/AddAdminScreen.dart';
import 'package:food_app/screens/admin/admin_profile_screen.dart';
import 'package:food_app/screens/shared/welcome_screen.dart';

import '../auth/admin_signup_screen.dart';
import '../merchant/merchant_reports_screen.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  Widget _currentScreen = const AdminDashboardView();
  String _currentTitle = 'Dashboard';

  void _selectScreen(Widget screen, String title) {
    Navigator.of(context).pop(); // Close the drawer
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Admin Panel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Manage Profile'),
              onTap: () => _selectScreen(const AdminProfileScreen(), 'My Profile'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Are you sure you want to logout?'),
                    actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    actions: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (shouldLogout ?? false) {
                  authProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _currentScreen,
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? authToken = authProvider.token; // Retrieve token from AuthProvider

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardButton(
            context,
            icon: Icons.people_outline,
            label: 'Customer Management',
            onPressed: () {
              if (authToken != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerManagementScreen(authToken: authToken),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Authentication token not found. Please log in.')),
                );
              }
            },
          ),
          _buildDashboardButton(
            context,
            icon: Icons.store_outlined,
            label: 'Merchant Management',
            onPressed: () {
              if (authToken != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MerchantManagementScreen(authToken: authToken),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Authentication token not found. Please log in.')),
                );
              }
            },
          ),
          // _buildDashboardButton(
          //   context,
          //   icon: Icons.menu_book_outlined,
          //   label: 'Menu & Order Monitoring',
          //   onPressed: () {
          //     if (authToken != null) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => CustomerManagementScreen(authToken: authToken),
          //         ),
          //       );
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Authentication token not found. Please log in.')),
          //       );
          //     }
          //   },
          // ),
          _buildDashboardButton(
            context,
            icon: Icons.bar_chart_outlined,
            label: 'Reports & Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MerchantReportsScreen()),
              );
            },
          ),
          _buildDashboardButton(
            context,
            icon: Icons.settings_outlined,
            label: 'Add New Admin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSignupScreen()),
              );
            },
          ),
          // _buildDashboardButton(
          //   context,
          //   icon: Icons.account_balance_outlined,
          //   label: 'Financial & Top-Up Control',
          //   onPressed: () {
          //     if (authToken != null) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => CustomerManagementScreen(authToken: authToken),
          //         ),
          //       );
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Authentication token not found. Please log in.')),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}