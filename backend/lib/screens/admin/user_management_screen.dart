import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  bool isActive;

  User({required this.id, required this.name, required this.email, required this.role, required this.isActive});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      // The backend now sends 'active' but 'isActive' is also fine. Ensure consistency.
      isActive: json['active'] ?? json['isActive'] ?? false,
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  List<User> _customers = [];
  List<User> _merchants = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      // FIXED: Using the correct constant from the updated ApiConstants file.
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.adminGetAllUsers),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> allUsersJson = jsonDecode(response.body);
          final allUsers = allUsersJson.map((json) => User.fromJson(json)).toList();

          setState(() {
            _customers = allUsers.where((u) => u.role == 'CUSTOMER').toList();
            _merchants = allUsers.where((u) => u.role == 'MERCHANT').toList();
          });
        } else {
          final responseBody = jsonDecode(response.body);
          setState(() => _errorMessage = responseBody['message'] ?? 'Failed to load users.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Could not connect to the server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(User user, bool newStatus) async {
    final originalStatus = user.isActive;
    setState(() => user.isActive = newStatus); // Optimistic UI update

    try {
      final token = await _storage.read(key: 'jwt_token');
      // Correctly construct the URL for activation/deactivation
      final url = newStatus
          ? '${ApiConstants.baseUrl}${ApiConstants.adminActivateUser}${user.id}/activate'
          : '${ApiConstants.baseUrl}${ApiConstants.adminDeactivateUser}${user.id}/deactivate';

      final response = await http.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted && response.statusCode != 200) {
        setState(() => user.isActive = originalStatus); // Revert on failure
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update user status.'), backgroundColor: Colors.red)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} has been ${newStatus ? "activated" : "deactivated"}'))
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => user.isActive = originalStatus);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred. Please try again.'), backgroundColor: Colors.red)
        );
      }
    }
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUserList(_customers, 'No customers found.'),
        _buildUserList(_merchants, 'No merchants found.'),
      ],
    );
  }

  Widget _buildUserList(List<User> users, String emptyMessage) {
    if (users.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Icon(user.role == 'CUSTOMER' ? Icons.person : Icons.store)),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: Switch(
                value: user.isActive,
                onChanged: (newValue) => _toggleUserStatus(user, newValue),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}