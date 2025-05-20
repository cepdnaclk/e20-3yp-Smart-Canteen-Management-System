import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required String email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _verificationCode = '';

  @override
  void initState() {
    super.initState();
    // Set up listeners for each field
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        if (_controllers[i].text.length == 1 && i < _controllers.length - 1) {
          _focusNodes[i + 1].requestFocus();
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

  void _verifyCode() {
    setState(() {
      _verificationCode = _controllers.map((controller) => controller.text).join();
    });

    // Here you would typically call your verification API
    debugPrint('Verification code: $_verificationCode');

    // Show a dialog or navigate on success
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text('Code $_verificationCode verified successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            const Text(
              'We have sent a 4-digit code to your email address. Please enter it below.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Code input fields
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

            // Verify button
            ElevatedButton(
              onPressed: _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Resend code option
            TextButton(
              onPressed: () {
                // Resend code logic
                debugPrint('Resend code pressed');
              },
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