// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/providers/auth_provider.dart';
// import 'package:food_app/screens/auth/forgot_password_screen.dart';
// import 'package:food_app/screens/auth/signup_screen.dart';
// import 'package:food_app/screens/customer/home_screen.dart';
// import 'package:food_app/screens/merchant/home.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:food_app/widgets/custom_scaffold.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
//
// class SignInScreen extends StatefulWidget {
//   const SignInScreen({super.key});
//
//   @override
//   State<SignInScreen> createState() => _SignInScreenState();
// }
//
// class _SignInScreenState extends State<SignInScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//
//   Future<void> _loginUser() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'email': _emailController.text.trim(),
//           'password': _passwordController.text
//         }),
//       );
//
//       final responseData = jsonDecode(response.body);
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           final authProvider = Provider.of<AuthProvider>(context, listen: false);
//           await authProvider.login(
//             responseData['token'],
//             responseData['email'],
//             responseData['role'],
//           );
//
//           NotificationUtils.showAnimatedPopup(
//             context,
//             title: 'Login Successful',
//             message: 'Welcome back!',
//             isSuccess: true,
//             onOkPressed: () {
//               Navigator.of(context).pop(); // Close the dialog
//               if (authProvider.role == 'CUSTOMER') {
//                 Navigator.of(context).pushAndRemoveUntil(
//                     MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
//               } else if (authProvider.role == 'MERCHANT') {
//                 Navigator.of(context).pushAndRemoveUntil(
//                     MaterialPageRoute(builder: (_) => const MerchantHomePage()), (route) => false);
//               }
//             },
//           );
//         } else {
//           NotificationUtils.showAnimatedPopup(
//             context,
//             title: 'Login Failed',
//             message: responseData['message'] ?? 'Invalid credentials.',
//             isSuccess: false,
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         NotificationUtils.showAnimatedPopup(
//           context,
//           title: 'Error',
//           message: 'Could not connect to the server. Please try again later.',
//           isSuccess: false,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffold(
//       backgroundImage: 'assets/images/welcomebg.jpg',
//       child: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset('assets/images/logo.png', width: 120, height: 120),
//                 const SizedBox(height: 20),
//                 const Text("Sign In", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 30),
//                 TextFormField(
//                   controller: _emailController,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: const InputDecoration(
//                     hintText: 'Email',
//                     hintStyle: TextStyle(color: Colors.white70),
//                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
//                     focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
//                     prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
//                   ),
//                   validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: InputDecoration(
//                     hintText: 'Password',
//                     hintStyle: const TextStyle(color: Colors.white70),
//                     prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
//                     enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
//                     focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
//                     suffixIcon: IconButton(
//                       icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
//                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                     ),
//                   ),
//                   validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
//                 ),
//                 const SizedBox(height: 10),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
//                     child: const Text('Forgot Password?', style: TextStyle(color: Colors.white)),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _loginUser,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black,
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
//                         : const Text('Sign In'),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 GestureDetector(
//                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
//                   child: const Text.rich(
//                     TextSpan(
//                       text: "Don't have an account? ",
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                       children: [
//                         TextSpan(
//                           text: "Sign up",
//                           style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/admin/AdminHomePage.dart'; // <-- IMPORT aDMIN HOME PAGE
import 'package:food_app/screens/auth/forgot_password_screen.dart';
import 'package:food_app/screens/auth/signup_screen.dart';
import 'package:food_app/screens/customer/home_screen.dart';
import 'package:food_app/screens/merchant/home.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/custom_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text
        }),
      );

      final responseData = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.login(
            responseData['token'],
            responseData['email'],
            responseData['role'],
            responseData['username'],
          );

          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Login Successful',
            message: 'Welcome back!',
            isSuccess: true,
            onOkPressed: () {
              Navigator.of(context).pop(); // Close the dialog

              // --- THIS IS THE CORRECTED NAVIGATION LOGIC ---
              if (authProvider.role == 'ADMIN') {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AdminHomePage()), (route) => false);
              } else if (authProvider.role == 'MERCHANT') {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MerchantHomePage()), (route) => false);
              } else { // Default to customer
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
              }
            },
          );
        } else {
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Login Failed',
            message: responseData['message'] ?? 'Invalid credentials.',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: 'Could not connect to the server. Please try again later.',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundImage: 'assets/images/welcomebg.jpg',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 120, height: 120),
                const SizedBox(height: 20),
                const Text("Sign In", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
                  ),
                  validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      children: [
                        TextSpan(
                          text: "Sign up",
                          style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}