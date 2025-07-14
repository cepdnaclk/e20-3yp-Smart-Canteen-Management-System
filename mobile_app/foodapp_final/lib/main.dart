// // import 'package:flutter/material.dart';
// // import 'package:food_app/providers/auth_provider.dart';
// // import 'package:food_app/providers/cart_provider.dart';
// // import 'package:food_app/providers/theme_provider.dart';
// // import 'package:food_app/screens/shared/splash_screen.dart';
// // import 'package:provider/provider.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MultiProvider(
// //       providers: [
// //         ChangeNotifierProvider(create: (_) => AuthProvider()),
// //         ChangeNotifierProvider(create: (_) => CartProvider()),
// //         ChangeNotifierProvider(create: (_) => ThemeProvider()),
// //       ],
// //       child: Consumer<ThemeProvider>(
// //         builder: (context, themeProvider, child) {
// //           return MaterialApp(
// //             title: 'Smart Canteen',
// //             debugShowCheckedModeBanner: false,
// //             theme: themeProvider.getTheme(),
// //             home: const SplashScreen(),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:food_app/providers/auth_provider.dart';
// import 'package:food_app/providers/cart_provider.dart';
// import 'package:food_app/providers/theme_provider.dart';
// import 'package:food_app/screens/shared/splash_screen.dart';
// import 'package:provider/provider.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => CartProvider()),
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//       ],
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, child) {
//           return MaterialApp(
//             title: 'Smart Canteen',
//             debugShowCheckedModeBanner: false,
//             theme: themeProvider.getTheme(),
//             home: const SplashScreen(),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/theme_provider.dart';
import 'package:food_app/screens/shared/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Canteen',
            debugShowCheckedModeBanner: false,
            // ✨ FIX: Use the 'themeData' getter instead of the old method
            theme: themeProvider.themeData,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}