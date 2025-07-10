import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  final Widget? child;
  final String? backgroundImage;

  const CustomScaffold({
    super.key,
    this.child,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (backgroundImage != null)
            Image.asset(
              backgroundImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          if (backgroundImage != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          SafeArea(child: child!),
        ],
      ),
    );
  }
}