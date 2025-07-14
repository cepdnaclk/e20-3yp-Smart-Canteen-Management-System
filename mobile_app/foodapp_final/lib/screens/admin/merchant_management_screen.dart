import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/utils/notification_utils.dart'; // Import NotificationUtils

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
  final String? canteenName;
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
    this.canteenName,
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
            (e) => e.toString().split('.').last.toUpperCase() == (json['role'] ?? 'MERCHANT'),
        orElse: () => Role.MERCHANT,
      ),
      isActive: json['active'] as bool? ?? true,
      canteenName: json['canteenName'],
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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('MerchantManagementScreen initialized with authToken: ${widget.authToken}');
    if (widget.authToken.isEmpty || widget.authToken == 'null' || !widget.authToken.startsWith('eyJ')) {
      NotificationUtils.showAnimatedPopup(
        context,
        title: 'Authentication Error',
        message: 'Invalid authentication token. Please log in again.',
        isSuccess: false,
        onOkPressed: _promptReAuthentication,
      );
    } else {
      _fetchMerchants();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMerchants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      };
      final response = await http.get(
        Uri.parse('http://192.168.237.203:8081/api/admin/merchants?active=true'),
        headers: headers,
      );
      print('Fetch merchants response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _merchants = data.map((e) => User.fromJson(e)).toList();
            _filteredMerchants = _merchants;
            _isLoading = false;
          });
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Success',
            message: 'Merchants fetched successfully.',
            isSuccess: true,
          );
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format: ${response.body}';
            _isLoading = false;
          });
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Error',
            message: _errorMessage!,
            isSuccess: false,
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Authentication Error',
          message: _errorMessage!,
          isSuccess: false,
          onOkPressed: _promptReAuthentication,
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch merchants: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: _errorMessage!,
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching merchants: $e';
        _isLoading = false;
      });
      NotificationUtils.showAnimatedPopup(
        context,
        title: 'Error',
        message: _errorMessage!,
        isSuccess: false,
      );
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredMerchants = _merchants;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      };
      final response = await http.get(
        Uri.parse('http://192.168.237.203:8081/api/admin/users/search?name=$query&role=MERCHANT&active=true'),
        headers: headers,
      );
      print('Search merchants response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _filteredMerchants = data.map((e) => User.fromJson(e)).toList();
            _isLoading = false;
          });
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Success',
            message: 'Search completed successfully.',
            isSuccess: true,
          );
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format: ${response.body}';
            _isLoading = false;
          });
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Error',
            message: _errorMessage!,
            isSuccess: false,
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Authentication Error',
          message: _errorMessage!,
          isSuccess: false,
          onOkPressed: _promptReAuthentication,
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to search merchants: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: _errorMessage!,
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching merchants: $e';
        _isLoading = false;
      });
      NotificationUtils.showAnimatedPopup(
        context,
        title: 'Error',
        message: _errorMessage!,
        isSuccess: false,
      );
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      };
      final response = await http.put(
        Uri.parse('http://192.168.237.203:8081/api/admin/users/${user.id}/toggle-active?role=MERCHANT'),
        headers: headers,
      );
      print('Toggle user status response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          user.isActive = isActive;
          if (!isActive) {
            _filteredMerchants.remove(user);
          }
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Success',
          message: '${user.email} has been ${isActive ? "activated" : "deactivated and notified by email"}.',
          isSuccess: true,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Authentication Error',
          message: _errorMessage!,
          isSuccess: false,
          onOkPressed: _promptReAuthentication,
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update user status: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: _errorMessage!,
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating user status: $e';
        _isLoading = false;
      });
      NotificationUtils.showAnimatedPopup(
        context,
        title: 'Error',
        message: _errorMessage!,
        isSuccess: false,
      );
    }
  }

  Future<void> _fetchTransactionHistory(User user) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      };
      final response = await http.get(
        Uri.parse('http://192.168.237.203:8081/api/admin/users/${user.id}/transactions'),
        headers: headers,
      );
      print('Fetch transactions response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            user.transactions = data.map((t) => Transaction.fromJson(t)).toList();
            _isLoading = false;
          });
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Success',
            message: 'Transaction history fetched successfully.',
            isSuccess: true,
          );
        } else {
          setState(() {
            _errorMessage = 'Unexpected transaction response format: ${response.body}';
            _isLoading = false;
          });
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Error',
            message: _errorMessage!,
            isSuccess: false,
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Authentication Error',
          message: _errorMessage!,
          isSuccess: false,
          onOkPressed: _promptReAuthentication,
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch transactions: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: _errorMessage!,
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching transactions: $e';
        _isLoading = false;
      });
      NotificationUtils.showAnimatedPopup(
        context,
        title: 'Error',
        message: _errorMessage!,
        isSuccess: false,
      );
    }
  }

  void _showTransactionHistory(BuildContext context, User user) async {
    await _fetchTransactionHistory(user);
    if (_errorMessage == null) {
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
  }

  void _promptReAuthentication() {
    Navigator.of(context).pushReplacementNamed('/login');
    Provider.of<AuthProvider>(context, listen: false).logout();
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  if (_errorMessage!.contains('Unauthorized') || _errorMessage!.contains('Forbidden'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: _promptReAuthentication,
                        child: const Text('Log In Again'),
                      ),
                    ),
                ],
              )
                  : _filteredMerchants.isEmpty
                  ? const Center(child: Text('No merchants found'))
                  : ListView.builder(
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
                          Text('Canteen: ${user.canteenName ?? 'Not specified'}'),
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