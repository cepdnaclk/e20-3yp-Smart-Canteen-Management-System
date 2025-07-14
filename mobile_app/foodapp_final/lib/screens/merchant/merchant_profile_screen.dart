import 'package:flutter/material.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/shared/welcome_screen.dart';
import 'package:provider/provider.dart';

import '../auth/forgot_password_screen.dart';

class MerchantProfileScreen extends StatelessWidget {
  const MerchantProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            //subtitle: const Text('Campus Bites'), // Fetch from API
            subtitle: Text(authProvider.name ?? 'Not logged in'),
            //trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          ),
          // ListTile(
          //   leading: const Icon(Icons.restaurant),
          //   title: const Text('Canteen Name'),
          //   //subtitle: const Text('Campus Bites'), // Fetch from API
          //   subtitle: Text(authProvider.canteenName ?? 'Not logged in'),
          //   //trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          // ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(authProvider.email ?? 'Not logged in'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // UPDATED: Navigates to the new screen
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
            },
          ),
          const Divider(height: 32),
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
}