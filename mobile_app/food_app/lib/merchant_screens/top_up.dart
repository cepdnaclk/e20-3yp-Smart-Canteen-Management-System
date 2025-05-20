import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Up Credit',
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: const TopUpPage(),
    );
  }
}

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _creditController = TextEditingController();

  bool _loading = false;
  bool _verified = false;
  String _statusMessage = '';
  String _customerName = '';

  final String backendBaseUrl = 'http://YOUR_BACKEND_IP:PORT'; // Update this

  Future<void> _verifyCustomer() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
      _verified = false;
      _customerName = '';
    });

    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/auth/verify-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _verified = true;
        _customerName = responseData['fullName'] ?? _usernameController.text;
        _statusMessage = 'Customer verified. You can now top up.';
      });
    } else {
      setState(() {
        _statusMessage = 'Invalid credentials. Try again.';
      });
    }
  }

  Future<void> _topUpCredit() async {
    final amount = double.tryParse(_creditController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _statusMessage = 'Enter a valid top-up amount.';
      });
      return;
    }

    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/merchant/topup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text.trim(),
        'amount': amount,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      setState(() {
        _statusMessage = 'Top-up successful!';
        _creditController.clear();
      });
    } else {
      setState(() {
        _statusMessage = 'Top-up failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Top-Up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.monetization_on, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Customer Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Customer Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verifyCustomer,
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text('Verify Customer'),
            ),
            const SizedBox(height: 20),
            if (_verified) ...[
              Text(
                'Customer: $_customerName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _creditController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Top-Up Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _loading ? null : _topUpCredit,
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirm Top-Up'),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color:
                    _statusMessage.contains('success')
                        ? Colors.green
                        : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
