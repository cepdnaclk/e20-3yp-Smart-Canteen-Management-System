import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:food_app/screens/login_screen.dart';
import 'package:food_app/widgets/custom_scaffold.dart';
import 'package:food_app/widgets/buttons.dart';
import 'package:food_app/merchant_screens/merchant_signup.dart';

import '../screens/email_verification.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // Added loading state

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.56.1:8081/api/auth/register/customer');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'fullName': null,
          'creditBalance': null,
          'CardID':null,
          'FingerprintID':null,

        }),
      );

      if (response.statusCode == 200) {
        // Registration successful - navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailVerificationScreen(email:_emailController.text,)),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                const SizedBox(height: 0),
                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) =>
                  value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) => value == null || value.length < 6
                      ? 'Minimum 6 characters'
                      : null,
                ),
                const SizedBox(height: 24),

                AnimatedActionButton(
                  label: _isLoading ? 'Creating Account...' : 'Create Account',
                  onTap: _isLoading ? null : () => registerUser(),
                  isOutlined: false,
                ),

                const SizedBox(height: 10),

                const Text(
                  'or sign in with',
                  style: TextStyle(
                    color: Color.fromARGB(255, 243, 241, 241),
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // handle google sign in
                      },
                      child: Image.asset(
                        'assets/icons/google.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // handle facebook sign in
                      },
                      child: Image.asset(
                        'assets/icons/facebook.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(
                        color: const Color.fromARGB(253, 255, 255, 255),
                        fontSize: 18,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign in",
                          style: TextStyle(
                            color: _isLoading ? Colors.grey : Colors.white,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MerchantSignupScreen(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Merchant ? ",
                      style: TextStyle(
                        color: const Color.fromARGB(253, 255, 255, 255),
                        fontSize: 18,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign in",
                          style: TextStyle(
                            color: _isLoading ? Colors.grey : Colors.white,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
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