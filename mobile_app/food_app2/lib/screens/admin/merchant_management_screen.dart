
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:food_app/providers/auth_provider.dart';

// Models
enum Role { ADMIN, CUSTOMER, MERCHANT }

class Transaction {
  final String id;
  final double amount;
  final String date;
  final String description;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      description: json['description'],
    );
  }
}

class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? cardID;
  final String? fingerprintID;
  final Role role;
  bool isActive;
  final double balance;
  List<Transaction> transactions;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.cardID,
    this.fingerprintID,
    required this.role,
    required this.isActive,
    this.balance = 0.0,
    this.transactions = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      cardID: json['cardID'],
      fingerprintID: json['fingerprintID'],
      role: Role.values.firstWhere(
            (e) => e.toString().split('.').last.toUpperCase() == json['role'],
        orElse: () => Role.MERCHANT,
      ),
      isActive: json['active'] ?? true,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MerchantManagementScreen extends StatefulWidget {
  final String authToken;

  const MerchantManagementScreen({super.key, required this.authToken});

  @override
  State<MerchantManagementScreen> createState() => _MerchantManagementScreenState();
}

class _MerchantManagementScreenState extends State<MerchantManagementScreen> {
  List<User> _merchants = [];
  List<User> _filteredMerchants = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('MerchantManagementScreen initialized with authToken: ${widget.authToken}');
    _fetchMerchants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMerchants() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/admin/merchants?active=true'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Fetch merchants response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _merchants = (data as List).map((e) => User.fromJson(e)).toList();
          _filteredMerchants = _merchants;
        });
      } else {
        _showErrorSnackBar('Failed to fetch merchants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching merchants: $e');
      _showErrorSnackBar('Error fetching merchants: $e');
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredMerchants = _merchants;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/admin/users/search?name=$query&role=MERCHANT&active=true'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Search merchants response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _filteredMerchants = (data as List).map((e) => User.fromJson(e)).toList();
        });
      } else {
        _showErrorSnackBar('Failed to search merchants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching merchants: $e');
      _showErrorSnackBar('Error searching merchants: $e');
    }
  }

  Future<void> _toggleUserStatus(User user, bool isActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isActive ? "Activate" : "Deactivate"} Account'),
        content: Text('Are you sure you want to ${isActive ? "activate" : "deactivate"} ${user.fullName}\'s account?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8081/api/admin/users/${user.id}/toggle-active?role=MERCHANT'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Toggle user status response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          user.isActive = isActive;
          if (!isActive) {
            _filteredMerchants.remove(user);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.email} has been ${isActive ? "activated" : "deactivated and notified by email"}'),
          ),
        );
      } else {
        _showErrorSnackBar('Failed to update user status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating user status: $e');
      _showErrorSnackBar('Error updating user status: $e');
    }
  }

  Future<void> _fetchTransactionHistory(User user) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/admin/users/${user.id}/transactions'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Fetch transactions response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          user.transactions = (data as List).map((t) => Transaction.fromJson(t)).toList();
        });
      } else {
        _showErrorSnackBar('Failed to fetch transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      _showErrorSnackBar('Error fetching transactions: $e');
    }
  }

  void _showTransactionHistory(BuildContext context, User user) async {
    await _fetchTransactionHistory(user);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${user.fullName}\'s Transaction History'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 300),
          child: user.transactions.isEmpty
              ? const Center(child: Text('No transactions available'))
              : ListView.builder(
            itemCount: user.transactions.length,
            itemBuilder: (context, index) {
              final transaction = user.transactions[index];
              return ListTile(
                title: Text(transaction.description),
                subtitle: Text('Date: ${transaction.date}'),
                trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMerchants,
              child: ListView.builder(
                itemCount: _filteredMerchants.length,
                itemBuilder: (context, index) {
                  final user = _filteredMerchants[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(user.fullName.isNotEmpty ? user.fullName : user.username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text('Balance: \$${user.balance.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Switch(
                        value: user.isActive,
                        onChanged: (newValue) => _toggleUserStatus(user, newValue),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      onTap: () => _showTransactionHistory(context, user),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
