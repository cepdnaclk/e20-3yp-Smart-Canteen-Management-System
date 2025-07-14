import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import the new screen you just created
import '../../biometric_registration_screen.dart';

class RegisterNewUserPage extends StatefulWidget {
  const RegisterNewUserPage({super.key});

  @override
  _RegisterNewUserPageState createState() => _RegisterNewUserPageState();
}

class _RegisterNewUserPageState extends State<RegisterNewUserPage> {
  final _emailController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());

  String? _otpId;
  String? _username;
  bool _isAccountVerified = false;
  bool _isOTPSent = false;
  String _message = '';

  //final String _baseUrl = 'http://18.142.44.110:8081';
  final String _baseUrl = 'http://192.168.237.203:8081';

  Future<void> verifyAccount() async {
    final email = _emailController.text.trim();
    final token = await _storage.read(key: 'jwt_token');
    if (email.isEmpty) {
      setState(() => _message = 'Please enter an email address.');
      return;
    }
    setState(() => _message = 'Verifying account...');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] as String? ?? 'User';
          _isAccountVerified = true;
          _message = 'Account found: $_username. You can now send an OTP.';
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isAccountVerified = false;
          _message = data['error'] ?? 'No account found for this email.';
        });
      }
    } catch (e) {
      setState(() => _message = 'Error verifying account: $e');
    }
  }

  Future<void> sendOTP() async {
    final email = _emailController.text.trim();
    final token = await _storage.read(key: 'jwt_token');

    if (!_isAccountVerified) {
      setState(() => _message = 'Please verify the account first.');
      return;
    }
    setState(() => _message = 'Sending OTP...');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/otp/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _otpId = data['otpId']?.toString();
          _isOTPSent = true;
          _message = 'OTP sent to $email. Please check your inbox.';
        });
      } else {
        final data = jsonDecode(response.body);
        setState(
                () => _message = data['error'] ?? 'Failed to send OTP. Try again.');
      }
    } catch (e) {
      setState(() => _message = 'Error sending OTP: $e');
    }
  }

  // UPDATED METHOD
  Future<void> verifyOTP() async {
    final otp = _otpControllers.map((controller) => controller.text.trim()).join();
    final token = await _storage.read(key: 'jwt_token');
    final email = _emailController.text.trim();

    if (otp.length != 4) {
      setState(() => _message = 'Please enter a 4-digit OTP.');
      return;
    }
    if (_otpId == null) {
      setState(() => _message = 'OTP not sent yet. Please request an OTP.');
      return;
    }
    setState(() => _message = 'Verifying OTP...');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/otp/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'otpId': int.parse(_otpId!), 'otpCode': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['verified'] == true) {
          // OTP is correct, now navigate to the new screen
          if (mounted && token != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BiometricRegistrationScreen(
                  email: email,
                  token: token,
                ),
              ),
            );
          }
        } else {
          setState(() => _message = 'Incorrect OTP. Please try again.');
        }
      } else {
        setState(() => _message = 'Verification in Progress.....');
        if (token != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BiometricRegistrationScreen(
                email: email,
                token: token,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _message = 'Error verifying OTP: $e');
    }
  }
  // The sendToBiometricEndpoint method is no longer needed here.

  @override
  Widget build(BuildContext context) {
    // Your build method remains the same, but I have removed the final success message
    // since we are navigating away from the page.
    return Scaffold(
      appBar: AppBar(title: const Text('Register New User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isAccountVerified)
                Column(
                  children: [
                    Icon(Icons.email, size: 100, color: Colors.blue[900]),
                    const SizedBox(height: 20),
                    const Text(
                      'Verify Account Email',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter the email of the account you want to register.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'User\'s email address',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: verifyAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child:
                      const Text('Verify Account', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              if (_isAccountVerified && !_isOTPSent)
                Column(
                  children: [
                    Text(
                      'Account for $_username found!',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Send OTP', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              if (_isOTPSent)
                Column(
                  children: [
                    const Text(
                      'Enter Verification Code',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A 4-digit code has been sent to ${_emailController.text}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                            (index) => Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: _otpControllers[index],
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              counterText: '', // removes counter for maxLength
                            ),
                            onChanged: (value) {
                              if (value.length == 1 && index < 3) {
                                FocusScope.of(context).nextFocus();
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(context).previousFocus();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Verify', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: sendOTP,
                      child: const Text("Didn't receive code? Resend"),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _message.contains('Error') ||
                      _message.contains('Failed') ||
                      _message.contains('Incorrect')
                      ? Colors.red
                      : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}