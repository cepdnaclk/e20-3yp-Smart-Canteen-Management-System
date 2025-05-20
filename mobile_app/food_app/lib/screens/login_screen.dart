import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:food_app/widgets/custom_scaffold.dart';
import 'package:food_app/widgets/buttons.dart';
import 'package:food_app/screens/signup_screen.dart';

import '../customer_screens/home_screen.dart';

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

  Future<void> loginUser(String email, String password) async {
    final url = Uri.parse('http://192.168.204.203:8080/api/auth/login');
    /*
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // TODO: Store token securely (e.g. with flutter_secure_storage)
        // Navigate to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
*/
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
                const Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator:
                      (value) =>
                          value == null || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                ),
                const SizedBox(height: 24),

                /*
                AnimatedActionButton(
                  label: 'Sign In',
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      loginUser(_emailController.text, _passwordController.text);
                    }
                  },
                  isOutlined: false,
                ),*/
                ///////////////////////////////////////////////
                AnimatedActionButton(
                  label: 'Sign In',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  isOutlined: false,
                ),

                //////////////////////////////////////////////
                const SizedBox(height: 16),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Color.fromARGB(253, 255, 255, 255),
                        fontSize: 18,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign up",
                          style: TextStyle(
                            color: Colors.white,
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
