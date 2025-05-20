import 'package:flutter/material.dart';
import 'package:food_app/screens/login_screen.dart';
import 'package:food_app/widgets/custom_scaffold.dart';
import 'package:food_app/widgets/buttons.dart';
import 'package:food_app/screens/signup_screen.dart';
import 'package:food_app/customer_screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundImage: 'assets/images/welcomebg.jpg',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            const SizedBox(height: 20),
            const Text(
              "WELCOME",
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),

            AnimatedActionButton(
              label: 'Sign In',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              isOutlined: false,
            ),

            const SizedBox(height: 16),

            AnimatedActionButton(
              label: 'Sign Up',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              isOutlined: true,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
