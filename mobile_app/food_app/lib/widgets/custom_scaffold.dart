import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({
    super.key,
    this.child,
    this.backgroundImage,
    
  });
  final Widget? child;
  final String? backgroundImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 238, 238, 243),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (backgroundImage != null)
            Image.asset(
              backgroundImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          SafeArea(child: child!),
        ],
      ),
    );
  }
}
