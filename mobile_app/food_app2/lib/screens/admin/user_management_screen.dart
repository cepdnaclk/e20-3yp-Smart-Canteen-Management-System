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
    print('Parsing user JSON: $json');
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      cardID: json['cardID'],
      fingerprintID: json['fingerprintID'],
      role: Role.values.firstWhere(
            (e) => e.toString().split('.').last.toUpperCase() == (json['role'] ?? 'CUSTOMER'),
        orElse: () => Role.CUSTOMER,
      ),
      isActive: json['active'] as bool? ?? true, // Ensure boolean parsing
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomerManagementScreen extends StatefulWidget {
  final String authToken;

  const CustomerManagementScreen({super.key, required this.authToken});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<User> _customers = [];
  List<User> _filteredCustomers = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.authToken.isEmpty || widget.authToken == 'null' || !widget.authToken.startsWith('eyJ')) {
      print('Error: authToken is invalid (empty: ${widget.authToken.isEmpty}, null: ${widget.authToken == 'null'}, startsWith eyJ: ${widget.authToken.startsWith('eyJ')})');
      setState(() {
        _errorMessage = 'Invalid authentication token. Please log in again.';
      });
    } else {
      print('CustomerManagementScreen initialized with authToken (length: ${widget.authToken.length}): ${widget.authToken.substring(0, 10)}...');
      _fetchCustomers();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      };
      print('Sending request with headers: Authorization: Bearer ${widget.authToken.substring(0, 10)}...');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/admin/customers'),
        headers: headers,
      );
      print('Fetch customers response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _customers = data.map((e) {
              final user = User.fromJson(e);
              print('Customer ${user.username} isActive: ${user.isActive}');
              return user;
            }).toList().where((u) => u.role == Role.CUSTOMER).toList();
            _filteredCustomers = _customers;
            _isLoading = false;
            print('Fetched ${_customers.length} customers');
          });
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format: ${response.body}';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch customers: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() {
        _errorMessage = 'Error fetching customers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = _customers;
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
      print('Sending search request with headers: Authorization: Bearer ${widget.authToken.substring(0, 10)}...');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/admin/users/search?name=$query&role=CUSTOMER'),
        headers: headers,
      );
      print('Search customers response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _filteredCustomers = data.map((e) {
              final user = User.fromJson(e);
              print('Search result ${user.username} isActive: ${user.isActive}');
              return user;
            }).toList().where((u) => u.role == Role.CUSTOMER).toList();
            _isLoading = false;
            print('Found ${_filteredCustomers.length} customers for query: $query');
          });
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format: ${response.body}';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to search customers: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching customers: $e');
      setState(() {
        _errorMessage = 'Error searching customers: $e';
        _isLoading = false;
      });
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
      print('Sending toggle status request for ${user.username} to set isActive: $isActive');
      final response = await http.put(
        Uri.parse('http://localhost:8081/api/admin/users/${user.id}/toggle-active?role=CUSTOMER'),
        headers: headers,
      );
      print('Toggle user status response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          user.isActive = isActive;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.email} has been ${isActive ? "activated" : "deactivated and notified by email"}'),
          ),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to update user status: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating user status: $e');
      setState(() {
        _errorMessage = 'Error updating user status: $e';
        _isLoading = false;
      });
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
      print('Sending transaction request with headers: Authorization: Bearer ${widget.authToken.substring(0, 10)}...');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/admin/users/${user.id}/transactions'),
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
        } else {
          setState(() {
            _errorMessage = 'Unexpected transaction response format: ${response.body}';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'Unauthorized: Invalid or expired token. Please log in again.'
              : 'Forbidden: Authentication failed. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch transactions: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _errorMessage = 'Error fetching transactions: $e';
        _isLoading = false;
      });
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

  void _promptReAuthentication() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Error'),
        content: const Text('Your session has expired or is invalid. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Management')),
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
              onRefresh: _fetchCustomers,
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
                  : _filteredCustomers.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final user = _filteredCustomers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(user.fullName.isNotEmpty ? user.fullName : user.username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text('Balance: \$${user.balance.toStringAsFixed(2)}'),
                          Text('Status: ${user.isActive ? "Active" : "Inactive"}'),
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