import 'package:flutter/material.dart';

// Dummy models for demonstration. Replace with your actual models.
class Customer {
  final String id;
  final String name;
  final String email;
  bool isActive;

  Customer({required this.id, required this.name, required this.email, this.isActive = true});
}

class Merchant {
  final String id;
  final String canteenName;
  final String email;
  bool isActive;

  Merchant({required this.id, required this.canteenName, required this.email, this.isActive = true});
}


class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Replace with actual API calls
  final List<Customer> _customers = [
    Customer(id: 'c1', name: 'John Doe', email: 'john.d@example.com'),
    Customer(id: 'c2', name: 'Jane Smith', email: 'jane.s@example.com', isActive: false),
  ];

  final List<Merchant> _merchants = [
    Merchant(id: 'm1', canteenName: 'Campus Bites', email: 'merchant1@example.com'),
    Merchant(id: 'm2', canteenName: 'Quick Eats', email: 'merchant2@example.com'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleUserStatus(dynamic user, bool isActive) {
    // In a real app, you would make an API call here to
    // ApiConstants.adminActivateUser or ApiConstants.adminDeactivateUser
    setState(() {
      user.isActive = isActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.email} has been ${isActive ? "activated" : "deactivated"}'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Customers'),
            Tab(icon: Icon(Icons.store), text: 'Merchants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_customers),
          _buildUserList(_merchants),
        ],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final bool isCustomer = user is Customer;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(isCustomer ? user.name : user.canteenName),
            subtitle: Text(user.email),
            trailing: Switch(
              value: user.isActive,
              onChanged: (newValue) {
                _toggleUserStatus(user, newValue);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}