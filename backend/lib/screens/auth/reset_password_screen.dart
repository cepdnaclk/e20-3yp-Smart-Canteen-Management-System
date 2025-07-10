// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/screens/auth/login_screen.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:http/http.dart' as http;
//
// class ResetPasswordScreen extends StatefulWidget {
//   final String email;
//   const ResetPasswordScreen({super.key, required this.email});
//
//   @override
//   State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
// }
//
// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final _tokenController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//
//   Future<void> _resetPassword() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       // API CALL IMPLEMENTED
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'token': _tokenController.text.trim(),
//           'newPassword': _passwordController.text,
//         }),
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           NotificationUtils.showAnimatedPopup(
//             context,
//             title: 'Success!',
//             message: 'Your password has been reset. Please log in with your new password.',
//             isSuccess: true,
//             onOkPressed: () {
//               Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (_) => const SignInScreen()),
//                     (route) => false,
//               );
//             },
//           );
//         } else {
//           NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Invalid token or an error occurred.', isSuccess: false);
//         }
//       }
//     } catch(e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
//     } finally {
//       if(mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Enter New Password')),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text("A reset token was sent to ${widget.email}. Please enter it below.", textAlign: TextAlign.center),
//               const SizedBox(height: 24),
//               TextFormField(
//                 controller: _tokenController,
//                 decoration: const InputDecoration(labelText: 'Reset Token', border: OutlineInputBorder()),
//                 validator: (value) => value!.isEmpty ? 'Please enter the token' : null,
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
//                 validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _resetPassword,
//                   child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Reset Password'),
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
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _tokenController.text.trim(),
          'newPassword': _passwordController.text,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Success!',
            message: 'Your password has been reset. Please log in with your new password.',
            isSuccess: true,
            onOkPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
              );
            },
          );
        } else {
          NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Invalid code or an error occurred.', isSuccess: false);
        }
      }
    } catch(e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter New Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("A reset code was sent to ${widget.email}. Please enter it below.", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Reset Code', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter the code' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Reset Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
