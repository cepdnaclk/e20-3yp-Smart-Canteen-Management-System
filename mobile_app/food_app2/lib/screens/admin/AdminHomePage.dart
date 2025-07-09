import 'package:flutter/material.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/admin/AddAdminScreen.dart';
import 'package:food_app/screens/admin/admin_dashboard_screen.dart';
import 'package:food_app/screens/admin/admin_profile_screen.dart';
import 'package:food_app/screens/admin/admin_reports_screen.dart';
import 'package:food_app/screens/admin/user_management_screen.dart';
import 'package:food_app/screens/shared/welcome_screen.dart';
import 'package:provider/provider.dart';

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
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => _selectScreen(const AdminDashboardView(), 'Dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('User Management'),
              onTap: () => _selectScreen(const UserManagementScreen(), 'User Management'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Add New Admin'),
              onTap: () => _selectScreen(const AddAdminScreen(), 'Add New Admin'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Platform Reports'),
              onTap: () => _selectScreen(const AdminReportsScreen(), 'Platform Reports'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('My Profile'),
              onTap: () => _selectScreen(const AdminProfileScreen(), 'My Profile'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    //title: const Text('Confirm Logout'),
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
