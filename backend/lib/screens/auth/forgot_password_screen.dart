// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/screens/auth/reset_password_screen.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:http/http.dart' as http;
//
// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});
//
//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }
//
// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final _emailController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//
//   Future<void> _sendResetLink() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       // API CALL IMPLEMENTED
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.forgotPassword),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'email': _emailController.text.trim()}),
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           NotificationUtils.showAnimatedPopup(
//             context,
//             title: 'Check Your Email',
//             message: 'A password reset token has been sent to ${_emailController.text}.',
//             isSuccess: true,
//             onOkPressed: () {
//               Navigator.of(context).pop(); // Close dialog
//               Navigator.of(context).pushReplacement(MaterialPageRoute(
//                 builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
//               ));
//             },
//           );
//         } else {
//           NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not process request. Please check the email and try again.', isSuccess: false);
//         }
//       }
//     } catch (e) {
//       if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Reset Password')),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.lock_reset, size: 60, color: Colors.deepPurple),
//               const SizedBox(height: 24),
//               const Text('Enter your email and we will send you a token to reset your password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
//               const SizedBox(height: 24),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _sendResetLink,
//                   child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Reset Token'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




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

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text.trim()}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Check Your Email',
            message: 'A password reset code has been sent to ${_emailController.text}.',
            isSuccess: true,
            onOkPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // **FIX:** Navigate to the ResetPasswordScreen with the user's email.
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
              ));
            },
          );
        } else {
          NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not process request. Please check the email and try again.', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
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
              const Text('Enter your email and we will send you a code to reset your password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Reset Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
