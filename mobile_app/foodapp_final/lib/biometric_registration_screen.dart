
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class BiometricRegistrationScreen extends StatefulWidget {
  final String email;
  final String token;

  const BiometricRegistrationScreen({
    Key? key,
    required this.email,
    required this.token,
  }) : super(key: key);

  @override
  _BiometricRegistrationScreenState createState() =>
      _BiometricRegistrationScreenState();
}

class _BiometricRegistrationScreenState
    extends State<BiometricRegistrationScreen> {
  bool _isSending = false;
  final String _baseUrl = 'http://18.142.44.110:8081';

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/success.json',
                repeat: false,
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'Signal Sent Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // New helper function to show the error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/error.json',
                repeat: false,
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to Send Signal!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendBiometricData() async {
    setState(() {
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/merchant/update-biometrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'email': widget.email}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _showSuccessDialog();
        } else {
          // Show the error dialog with the server's message
          _showErrorDialog('Server responded with: ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        // Show the error dialog with the exception message
        _showErrorDialog('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Registration'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registering Biometrics for:',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Registration in Progress...',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSending ? null : _sendBiometricData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                ),
                child: _isSending
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
                    : const Text(
                  'Send Biometric Signal',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}