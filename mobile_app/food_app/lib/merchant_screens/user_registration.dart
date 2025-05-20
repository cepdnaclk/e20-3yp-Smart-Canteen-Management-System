import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fingerprint Registration',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const FingerprintRegisterPage(),
    );
  }
}

class FingerprintRegisterPage extends StatefulWidget {
  const FingerprintRegisterPage({super.key});

  @override
  State<FingerprintRegisterPage> createState() =>
      _FingerprintRegisterPageState();
}

class _FingerprintRegisterPageState extends State<FingerprintRegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _authenticated = false;
  String _statusMessage = '';

  final String backendBaseUrl = 'http://YOUR_BACKEND_IP:PORT';

  Future<void> _verifyCredentials() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
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
      setState(() {
        _authenticated = true;
        _statusMessage = 'User authenticated. Place your finger on the sensor.';
      });
      _registerFingerprint();
    } else {
      setState(() {
        _authenticated = false;
        _statusMessage = 'Invalid credentials. Try again.';
      });
    }
  }

  Future<void> _registerFingerprint() async {
    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/fingerprint/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text.trim(),
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      setState(() {
        _statusMessage = 'Fingerprint registered successfully.';
      });
    } else {
      setState(() {
        _statusMessage = 'Fingerprint registration failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Fingerprint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.fingerprint, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                  labelText: 'Username', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password', prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verifyCredentials,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify & Register Fingerprint'),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _authenticated ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
