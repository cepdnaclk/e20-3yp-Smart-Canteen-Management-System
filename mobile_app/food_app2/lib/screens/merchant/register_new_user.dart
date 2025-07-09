import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterNewUserPage extends StatefulWidget {
  const RegisterNewUserPage({super.key});

  @override
  _RegisterNewUserPageState createState() => _RegisterNewUserPageState();
}

class _RegisterNewUserPageState extends State<RegisterNewUserPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  String? _otpId;
  bool _isOTPSent = false;
  String _message = '';

  Future<void> sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter an email address.');
      return;
    }
    setState(() => _message = 'Sending OTP...');
    final response = await http.post(
      Uri.parse('http://YOUR_BACKEND_URL/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _otpId = data['otpId'];
        _isOTPSent = true;
        _message = 'OTP sent to $email. Please check your inbox.';
      });
    } else {
      setState(() => _message = 'Failed to send OTP. Try again.');
    }
  }

  Future<void> verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      setState(() => _message = 'Please enter the 4-digit OTP.');
      return;
    }
    setState(() => _message = 'Verifying OTP...');
    final response = await http.post(
      Uri.parse('http://YOUR_BACKEND_URL/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'otpId': _otpId, 'otpCode': otp}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['verified'] == true) {
        setState(() => _message = 'OTP verified! Registering user...');
        await sendEmailToBiometric();
      } else {
        setState(() => _message = 'Incorrect OTP. Please try again.');
      }
    } else {
      setState(() => _message = 'Verification failed. Try again.');
    }
  }

  Future<void> sendEmailToBiometric() async {
    final email = _emailController.text.trim();
    final response = await http.post(
      Uri.parse('http://YOUR_BACKEND_URL/biometric/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      setState(() => _message = 'User registered successfully!');
    } else {
      setState(() => _message = 'Failed to register user. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isOTPSent) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'User Email'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: sendOTP,
                child: const Text('Send OTP'),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: verifyOTP,
                child: const Text('Verify OTP & Register'),
              ),
            ],
            const SizedBox(height: 16),
            Text(_message, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
