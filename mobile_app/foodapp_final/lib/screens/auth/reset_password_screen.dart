import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/screens/auth/login_screen.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword);
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text.trim();
    print('Sending reset request to: $url with code: $code'); // Debug log

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': code,
          'newPassword': newPassword,
        }),
      );

      print('Response status: ${response.statusCode}, body: ${response.body}'); // Debug log

      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Success',
            message: 'Your password has been reset successfully. Please log in with your new password.',
            isSuccess: true,
            onOkPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
              );
            },
          );
        } else {
          final errorMessage = json.decode(response.body)['error'] ?? 'Invalid code or an error occurred. Please try again.';
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
              const Icon(Icons.lock, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 24),
              Text(
                'Enter the 4-digit code sent to ${widget.email} and your new password.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Reset Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                (value == null || value.length != 4 || !RegExp(r'^\d{4}$').hasMatch(value))
                    ? 'Please enter a valid 4-digit code'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Reset Password'),
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
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}