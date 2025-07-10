import 'package:flutter/material.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/admin/admin_dashboard_screen.dart';
import 'package:food_app/screens/customer/budget_screen.dart';
import 'package:food_app/screens/customer/customer_profile_screen.dart';
import 'package:food_app/screens/customer/order_history_screen.dart';
import 'package:food_app/screens/merchant/manage_menu_screen.dart';
import 'package:food_app/screens/merchant/order_management_screen.dart';
import 'package:food_app/screens/shared/welcome_screen.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCustomer = authProvider.role == 'CUSTOMER';
    final isMerchant = authProvider.role == 'MERCHANT';
    final isAdmin = authProvider.role == 'ADMIN';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.role ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(authProvider.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                authProvider.email?.substring(0, 1).toUpperCase() ?? "U",
                style: TextStyle(fontSize: 40.0, color: Theme.of(context).primaryColor),
              ),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          if (isCustomer) ..._buildCustomerMenuItems(context),
          if (isMerchant) ..._buildMerchantMenuItems(context),
          if (isAdmin) ..._buildAdminMenuItems(context),
          const Divider(),
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
    );
  }

  List<Widget> _buildCustomerMenuItems(BuildContext context) {
    return [
      ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Home'), onTap: () => Navigator.pop(context)),
      ListTile(leading: const Icon(Icons.history), title: const Text('My Orders'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()))),
      ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('My Budget'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetDashboard()))),
      ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile & Settings'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerProfileScreen()))),
    ];
  }

  List<Widget> _buildMerchantMenuItems(BuildContext context) {
    return [
      ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
      ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Order Management'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen()))),
      ListTile(leading: const Icon(Icons.restaurant_menu_outlined), title: const Text('Manage Menu'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageMenuScreen()))),
    ];
  }

  List<Widget> _buildAdminMenuItems(BuildContext context) {
    return [
      ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Dashboard'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardView()))),
    ];
  }
}