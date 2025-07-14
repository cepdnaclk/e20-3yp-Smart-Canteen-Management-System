import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Helper to show an animation overlay from a given path
void showSuccessAnimation(BuildContext context, {required String animationPath}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.2), // Dim the background slightly
    barrierDismissible: false,
    builder: (BuildContext context) {
      // Automatically close the dialog after the animation would have played
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Lottie.asset(
            animationPath, // Use the path provided
            width: 150,
            height: 150,
            repeat: false, // Play the animation only once
          ),
        ),
      );
    },
  );
}