import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/screens/auth/reset_password_screen.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.forgotPassword);
    final email = _emailController.text.trim();
    print('Sending request to: $url with email: $email'); // Debug log

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print('Response status: ${response.statusCode}, body: ${response.body}'); // Debug log

      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Check Your Email',
            message: 'A 4-digit password reset code has been sent to $email.',
            isSuccess: true,
            onOkPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(email: email),
              ));
            },
          );
        } else {
          final errorMessage = json.decode(response.body)['error'] ?? 'Could not process request. Please check the email and try again.';
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Error',
            message: errorMessage,
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      print('Error: $e'); // Debug log
      if (mounted) {
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: 'Could not connect to the server. Please check your network and try again.',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 24),
              const Text(
                'Enter your email to receive a 4-digit code to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                (value == null || !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                    ? 'Please enter a valid email'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetCode,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Reset Code'),
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
    super.dispose();
  }
}