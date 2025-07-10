// import 'package:flutter/material.dart';
// import 'package:food_app/models/menu_item.dart';
//
// class CartProvider with ChangeNotifier {
//   final Map<int, int> _cart = {};
//   Map<int, MenuItem> _menuItemsMap = {};
//   Map<int, int> get cart => _cart;
//
//   void setMenuItems(List<MenuItem> items) {
//     _menuItemsMap = {for (var item in items) item.id: item};
//   }
//   void addToCart(int itemId) {
//     _cart.update(itemId, (value) => value + 1, ifAbsent: () => 1);
//     notifyListeners();
//   }
//   void removeFromCart(int itemId) {
//     if (_cart.containsKey(itemId) && _cart[itemId]! > 1) {
//       _cart[itemId] = _cart[itemId]! - 1;
//     } else {
//       _cart.remove(itemId);
//     }
//     notifyListeners();
//   }
//   void clearItemFromCart(int itemId) { _cart.remove(itemId); notifyListeners(); }
//   void clearCart() { _cart.clear(); notifyListeners(); }
//   int getQuantity(int itemId) => _cart[itemId] ?? 0;
//
//   double get totalAmount {
//     double total = 0.0;
//     _cart.forEach((itemId, quantity) {
//       final item = _menuItemsMap[itemId];
//       if (item != null) total += item.price * quantity;
//     });
//     return total;
//   }
//
//   List<MenuItem> get cartItems {
//     return _cart.keys.map((id) => _menuItemsMap[id]).where((item) => item != null).cast<MenuItem>().toList();
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/menu_item.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;

class CartProvider with ChangeNotifier {
  final Map<int, int> _cart = {};
  Map<int, MenuItem> _menuItemsMap = {};
  final _storage = const FlutterSecureStorage();

  Map<int, int> get cart => _cart;

  void setMenuItems(List<MenuItem> items) {
    _menuItemsMap = {for (var item in items) item.id: item};
  }

  void addToCart(int itemId) {
    _cart.update(itemId, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void removeFromCart(int itemId) {
    if (_cart.containsKey(itemId) && _cart[itemId]! > 1) {
      _cart[itemId] = _cart[itemId]! - 1;
    } else {
      _cart.remove(itemId);
    }
    notifyListeners();
  }

  void clearItemFromCart(int itemId) {
    _cart.remove(itemId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  int getQuantity(int itemId) => _cart[itemId] ?? 0;

  double get totalAmount {
    double total = 0.0;
    _cart.forEach((itemId, quantity) {
      final item = _menuItemsMap[itemId];
      if (item != null) {
        total += item.price * quantity;
      }
    });
    return total;
  }

  List<MenuItem> get cartItems {
    return _cart.keys.map((id) => _menuItemsMap[id]).where((item) => item != null).cast<MenuItem>().toList();
  }

  // --- NEW FUNCTIONALITY: Place Order with Error Handling ---
  Future<bool> placeOrder(BuildContext context) async {
    if (_cart.isEmpty) {
      NotificationUtils.showAnimatedPopup(
        context,
        title: "Empty Cart",
        message: "Please add items to your cart before placing an order.",
        isSuccess: false,
      );
      return false;
    }

    final token = await _storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final orderItems = _cart.entries.map((entry) {
      return {'menuItemId': entry.key, 'quantity': entry.value};
    }).toList();

    final body = json.encode({'orderItems': orderItems});

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.placeOrder),
        headers: headers,
        body: body,
      );

      // Use a local variable for the context check
      final currentContext = context;
      if (!Navigator.of(currentContext).mounted) return false;

      if (response.statusCode == 200) {
        NotificationUtils.showAnimatedPopup(
          currentContext,
          title: "Order Placed!",
          message: "Your order has been sent to the merchant.",
          isSuccess: true,
        );
        clearCart(); // Clear cart on successful order
        return true;
      } else {
        // **FIX:** Handle specific error messages from the backend
        final responseData = jsonDecode(response.body);
        String errorMessage = responseData['message'] ?? 'Failed to place order.';

        // Check for the "Insufficient stock" error
        if (errorMessage.contains('Insufficient stock')) {
          NotificationUtils.showAnimatedPopup(
            currentContext,
            title: 'Item Out of Stock',
            message: 'Sorry, an item in your cart is no longer available. Please review your cart.',
            isSuccess: false,
          );
        } else {
          // Handle other errors (e.g., insufficient balance)
          NotificationUtils.showAnimatedPopup(
            currentContext,
            title: 'Order Failed',
            message: errorMessage,
            isSuccess: false,
          );
        }
        return false;
      }
    } catch (e) {
      final currentContext = context;
      if (!Navigator.of(currentContext).mounted) return false;
      NotificationUtils.showAnimatedPopup(
        currentContext,
        title: 'Connection Error',
        message: 'Could not connect to the server.',
        isSuccess: false,
      );
      return false;
    }
  }
}
