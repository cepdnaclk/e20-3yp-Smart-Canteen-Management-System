// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
//
// class NotificationUtils {
//   static void showAnimatedPopup(
//       BuildContext context, {
//         required String title,
//         required String message,
//         required bool isSuccess,
//         VoidCallback? onOkPressed,
//       }) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Lottie.asset(
//                 isSuccess ? 'assets/animations/success.json' : 'assets/animations/error.json',
//                 width: 100,
//                 repeat: false,
//               ),
//               const SizedBox(height: 16),
//               Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: onOkPressed ?? () => Navigator.of(context).pop(),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NotificationUtils {
  /// Shows a beautiful animated pop-up that disappears automatically.
  static void showAnimatedPopup(
      BuildContext context, {
        required String title,
        required String message,
        required bool isSuccess,
        // This callback will be executed automatically after the dialog closes.
        VoidCallback? onOkPressed,
      }) {

    // The showDialog function returns a Future that completes when the dialog is popped.
    // We can use `.then()` to execute the callback after the dialog is gone.
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents users from dismissing it accidentally
      builder: (BuildContext dialogContext) {

        // Automatically close the dialog after a delay.
        // Lottie animations are typically 2-3 seconds long.
        Future.delayed(const Duration(milliseconds: 2500), () {
          // Ensure the context is still valid before trying to pop.
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                isSuccess ? 'assets/animations/success.json' : 'assets/animations/error.json',
                width: 120,
                height: 120,
                repeat: false,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          // --- REMOVED: The actions/button section is no longer needed ---
        );
      },
    ).then((_) {
      // This code runs *after* the dialog has been popped.
      // It's the safest place to execute the callback for navigation etc.
      onOkPressed?.call();
    });
  }
}
