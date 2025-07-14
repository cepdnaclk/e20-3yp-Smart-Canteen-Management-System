// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:food_app/api/api_constants.dart';
// // import 'package:food_app/screens/auth/email_verification.dart';
// // import 'package:food_app/screens/auth/login_screen.dart';
// // import 'package:food_app/screens/auth/merchant_signup_screen.dart';
// // import 'package:food_app/utils/notification_utils.dart';
// // import 'package:food_app/widgets/custom_scaffold.dart';
// // import 'package:http/http.dart' as http;
// //
// // class SignupScreen extends StatefulWidget {
// //   const SignupScreen({super.key});
// //
// //   @override
// //   State<SignupScreen> createState() => _SignupScreenState();
// // }
// //
// // class _SignupScreenState extends State<SignupScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _nameController = TextEditingController();
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   bool _obscurePassword = true;
// //   bool _isLoading = false;
// //
// //   Future<void> _registerUser() async {
// //     if (!_formKey.currentState!.validate()) return;
// //     setState(() => _isLoading = true);
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse(ApiConstants.baseUrl + ApiConstants.registerCustomer),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'username': _nameController.text.trim(),
// //           'fullName': _nameController.text.trim(),
// //           'email': _emailController.text.trim(),
// //           'password': _passwordController.text,
// //         }),
// //       );
// //       if (mounted) {
// //         if (response.statusCode == 200) {
// //           Navigator.of(context).pushReplacement(MaterialPageRoute(
// //             builder: (_) => EmailVerificationScreen(email: _emailController.text.trim()),
// //           ));
// //         } else {
// //           final responseData = jsonDecode(response.body);
// //           NotificationUtils.showAnimatedPopup(context, title: 'Signup Failed', message: responseData['message'] ?? 'An error occurred.', isSuccess: false);
// //         }
// //       }
// //     } catch (e) {
// //       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
// //     } finally {
// //       if(mounted) setState(() => _isLoading = false);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return CustomScaffold(
// //       backgroundImage: 'assets/images/welcomebg.jpg',
// //       child: Center(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(horizontal: 24),
// //           child: Form(
// //             key: _formKey,
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 const Text("Create Account", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
// //                 const SizedBox(height: 30),
// //                 TextFormField(
// //                   controller: _nameController,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: const InputDecoration(hintText: 'Full Name', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
// //                   validator: (value) => value!.isEmpty ? 'Enter your name' : null,
// //                 ),
// //                 const SizedBox(height: 16),
// //                 TextFormField(
// //                   controller: _emailController,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: const InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
// //                   validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
// //                 ),
// //                 const SizedBox(height: 16),
// //                 TextFormField(
// //                   controller: _passwordController,
// //                   obscureText: _obscurePassword,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: InputDecoration(
// //                     hintText: 'Password',
// //                     hintStyle: const TextStyle(color: Colors.white70),
// //                     enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
// //                     suffixIcon: IconButton(
// //                       icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
// //                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
// //                     ),
// //                   ),
// //                   validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 characters' : null,
// //                 ),
// //                 const SizedBox(height: 24),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: _isLoading ? null : _registerUser,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.white,
// //                       foregroundColor: Colors.black,
// //                     ),
// //                     child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Create Account'),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 GestureDetector(
// //                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen())),
// //                   child: const Text.rich(TextSpan(
// //                     text: "Already have an account? ",
// //                     style: TextStyle(color: Colors.white, fontSize: 16),
// //                     children: [TextSpan(text: "Sign In", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
// //                   )),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 GestureDetector(
// //                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MerchantSignupScreen())),
// //                   child: const Text.rich(TextSpan(
// //                     text: "Are you a merchant? ",
// //                     style: TextStyle(color: Colors.white, fontSize: 16),
// //                     children: [TextSpan(text: "Sign up here", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
// //                   )),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:food_app/api/api_constants.dart';
// // import 'package:food_app/screens/auth/admin_signup_screen.dart'; // Import the new admin screen
// // import 'package:food_app/screens/auth/email_verification.dart';
// // import 'package:food_app/screens/auth/login_screen.dart';
// // import 'package:food_app/screens/auth/merchant_signup_screen.dart';
// // import 'package:food_app/utils/notification_utils.dart';
// // import 'package:food_app/widgets/custom_scaffold.dart';
// // import 'package:http/http.dart' as http;
// //
// // class SignupScreen extends StatefulWidget {
// //   const SignupScreen({super.key});
// //
// //   @override
// //   State<SignupScreen> createState() => _SignupScreenState();
// // }
// //
// // class _SignupScreenState extends State<SignupScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _nameController = TextEditingController();
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   bool _obscurePassword = true;
// //   bool _isLoading = false;
// //
// //   Future<void> _registerUser() async {
// //     if (!_formKey.currentState!.validate()) return;
// //     setState(() => _isLoading = true);
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse(ApiConstants.baseUrl + ApiConstants.registerCustomer),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'username': _nameController.text.trim(),
// //           'fullName': _nameController.text.trim(),
// //           'email': _emailController.text.trim(),
// //           'password': _passwordController.text,
// //         }),
// //       );
// //       if (mounted) {
// //         if (response.statusCode == 200) {
// //           Navigator.of(context).pushReplacement(MaterialPageRoute(
// //             builder: (_) => EmailVerificationScreen(email: _emailController.text.trim()),
// //           ));
// //         } else {
// //           final responseData = jsonDecode(response.body);
// //           NotificationUtils.showAnimatedPopup(context, title: 'Signup Failed', message: responseData['message'] ?? 'An error occurred.', isSuccess: false);
// //         }
// //       }
// //     } catch (e) {
// //       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
// //     } finally {
// //       if(mounted) setState(() => _isLoading = false);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return CustomScaffold(
// //       backgroundImage: 'assets/images/welcomebg.jpg',
// //       child: Center(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(horizontal: 24),
// //           child: Form(
// //             key: _formKey,
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 const Text("Create Account", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
// //                 const SizedBox(height: 30),
// //                 TextFormField(
// //                   controller: _nameController,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: const InputDecoration(hintText: 'Full Name', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
// //                   validator: (value) => value!.isEmpty ? 'Enter your name' : null,
// //                 ),
// //                 const SizedBox(height: 16),
// //                 TextFormField(
// //                   controller: _emailController,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: const InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
// //                   validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
// //                 ),
// //                 const SizedBox(height: 16),
// //                 TextFormField(
// //                   controller: _passwordController,
// //                   obscureText: _obscurePassword,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: InputDecoration(
// //                     hintText: 'Password',
// //                     hintStyle: const TextStyle(color: Colors.white70),
// //                     enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
// //                     suffixIcon: IconButton(
// //                       icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
// //                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
// //                     ),
// //                   ),
// //                   validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 characters' : null,
// //                 ),
// //                 const SizedBox(height: 24),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: _isLoading ? null : _registerUser,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.white,
// //                       foregroundColor: Colors.black,
// //                     ),
// //                     child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Create Account'),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 GestureDetector(
// //                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen())),
// //                   child: const Text.rich(TextSpan(
// //                     text: "Already have an account? ",
// //                     style: TextStyle(color: Colors.white, fontSize: 16),
// //                     children: [TextSpan(text: "Sign In", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
// //                   )),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 GestureDetector(
// //                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MerchantSignupScreen())),
// //                   child: const Text.rich(TextSpan(
// //                     text: "Are you a merchant? ",
// //                     style: TextStyle(color: Colors.white, fontSize: 16),
// //                     children: [TextSpan(text: "Sign up here", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
// //                   )),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 // --- NEW ADMIN SIGNUP LINK ---
// //                 GestureDetector(
// //                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSignupScreen())),
// //                   child: const Text.rich(TextSpan(
// //                     text: "Are you an admin? ",
// //                     style: TextStyle(color: Colors.white, fontSize: 16),
// //                     children: [TextSpan(text: "Register here", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
// //                   )),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/screens/auth/email_verification.dart';
// import 'package:food_app/screens/auth/login_screen.dart';
// import 'package:food_app/screens/auth/merchant_signup_screen.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:food_app/widgets/custom_scaffold.dart';
// import 'package:http/http.dart' as http;
//
// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});
//
//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }
//
// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//
//   Future<void> _registerUser() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.registerCustomer),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'username': _nameController.text.trim(),
//           'fullName': _nameController.text.trim(),
//           'email': _emailController.text.trim(),
//           'password': _passwordController.text,
//         }),
//       );
//       if (mounted) {
//         if (response.statusCode == 200) {
//           Navigator.of(context).pushReplacement(MaterialPageRoute(
//             builder: (_) => EmailVerificationScreen(email: _emailController.text.trim()),
//           ));
//         } else {
//           final responseData = jsonDecode(response.body);
//           NotificationUtils.showAnimatedPopup(context, title: 'Signup Failed', message: responseData['message'] ?? 'An error occurred.', isSuccess: false);
//         }
//       }
//     } catch (e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
//     } finally {
//       if(mounted) setState(() => _isLoading = false);
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
//                 const Text("Create Account", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 30),
//                 TextFormField(
//                   controller: _nameController,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: const InputDecoration(hintText: 'Full Name', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
//                   validator: (value) => value!.isEmpty ? 'Enter your name' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _emailController,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: const InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
//                   validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: InputDecoration(
//                     hintText: 'Password',
//                     hintStyle: const TextStyle(color: Colors.white70),
//                     enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
//                     suffixIcon: IconButton(
//                       icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
//                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                     ),
//                   ),
//                   validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 characters' : null,
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _registerUser,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black,
//                     ),
//                     child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Create Account'),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 GestureDetector(
//                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen())),
//                   child: const Text.rich(TextSpan(
//                     text: "Already have an account? ",
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                     children: [TextSpan(text: "Sign In", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
//                   )),
//                 ),
//                 const SizedBox(height: 12),
//                 GestureDetector(
//                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MerchantSignupScreen())),
//                   child: const Text.rich(TextSpan(
//                     text: "Are you a merchant? ",
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                     children: [TextSpan(text: "Sign up here", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
//                   )),
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
import 'package:food_app/screens/auth/email_verification.dart';
import 'package:food_app/screens/auth/login_screen.dart';
import 'package:food_app/screens/auth/merchant_signup_screen.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/custom_scaffold.dart';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.registerCustomer),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _nameController.text.trim(),
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: _emailController.text.trim()),
          ));
        } else {
          final responseData = jsonDecode(response.body);
          NotificationUtils.showAnimatedPopup(context, title: 'Signup Failed', message: responseData['message'] ?? 'An error occurred.', isSuccess: false);
        }
      }
    } catch (e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not connect to the server.', isSuccess: false);
    } finally {
      if(mounted) setState(() => _isLoading = false);
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
                const Text("Create Account", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Full Name', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
                  validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen())),
                  child: const Text.rich(TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    children: [TextSpan(text: "Sign In", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
                  )),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MerchantSignupScreen())),
                  child: const Text.rich(TextSpan(
                    text: "Are you a merchant? ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    children: [TextSpan(text: "Sign up here", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold))],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
