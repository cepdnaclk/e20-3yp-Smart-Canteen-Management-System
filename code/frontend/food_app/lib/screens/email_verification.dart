import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:food_app/screens/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _verificationCode = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        if (_controllers[i].text.length == 1 && i < _controllers.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }
        if (_controllers[i].text.length == 1 && i == _controllers.length - 1) {
          _focusNodes[i].unfocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _verificationCode = _controllers.map((controller) => controller.text).join();
      _isLoading = true;
      _errorMessage = null;
    });

    // Validate code
    if (_verificationCode.length != 4 || !_verificationCode.contains(RegExp(r'^\d{4}$'))) {
      setState(() {
        _errorMessage = 'Please enter a valid 4-digit code';
        _isLoading = false;
      });
      return;
    }

    final String normalizedEmail = widget.email.trim().toLowerCase();
    if (kDebugMode) {
      print('Sending email: $normalizedEmail');
    }

    try {
      final url = Uri.parse('http://192.168.56.1:8081/api/auth/verify-email');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'code': _verificationCode,
        }),
      ).timeout(const Duration(seconds: 60), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        dynamic responseData;
        try {
          responseData = jsonDecode(response.body);
          if (responseData == null) {
            throw Exception('Empty response body');
          }
        } catch (e) {
          throw Exception('Invalid response format');
        }

        if (responseData is Map && (responseData['success'] == true || responseData['token'] != null)) {
          // Navigate to LoginScreen on success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        } else {
          setState(() {
            _errorMessage = (responseData['message'] as String?) ?? 'Invalid verification code';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to verify code: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      String error;
      if (e is SocketException) {
        error = 'Cannot connect to server. Check your network.';
      } else if (e is TimeoutException) {
        error = 'Request timed out. Try again later.';
      } else {
        error = 'Error connecting to server: $e';
      }
      setState(() {
        _errorMessage = error;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String normalizedEmail = widget.email.trim().toLowerCase();
    print('Resending to email: $normalizedEmail'); // Debug print

    try {
      final url = Uri.parse('http://192.168.56.1:8081/api/auth/resend-code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail}),
      ).timeout(const Duration(seconds: 60), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Verification code resent successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to resend code: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      String error;
      if (e is SocketException) {
        error = 'Cannot connect to server. Check your network.';
      } else if (e is TimeoutException) {
        error = 'Request timed out. Try again later.';
      } else {
        error = 'Error resending code: $e';
      }
      setState(() {
        _errorMessage = error;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Enter Verification Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a 4-digit code to ${widget.email}. Please enter it below.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Verify',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
              child: const Text(
                "Didn't receive code? Resend",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}