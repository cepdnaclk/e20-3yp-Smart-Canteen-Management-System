import 'package:flutter/material.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/theme_provider.dart';
import 'package:food_app/screens/customer/change_password_screen.dart';
import 'package:food_app/screens/customer/edit_profile_screen.dart';
import 'package:food_app/screens/shared/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});


  void _showColorPicker(BuildContext context) {
    Color pickerColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a theme color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Select'),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).setTheme(pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      onPressed: () { /* Implement image picker to call ApiConstants.customerProfilePicture */ },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(child: Text(authProvider.email ?? 'customer@example.com', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Change App Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showColorPicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Edit Profile Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // UPDATED: Navigates to the new screen
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // UPDATED: Navigates to the new screen
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
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