import 'package:flutter/material.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class QuantityToggle extends StatelessWidget {
  final int itemId;

  const QuantityToggle({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.getQuantity(itemId);

    if (quantity == 0) {
      return IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 30),
        onPressed: () {
          Provider.of<CartProvider>(context, listen: false).addToCart(itemId);
        },
        tooltip: 'Add to cart',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => Provider.of<CartProvider>(context, listen: false).removeFromCart(itemId),
            splashRadius: 18,
            tooltip: 'Remove one',
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => Provider.of<CartProvider>(context, listen: false).addToCart(itemId),
            splashRadius: 18,
            tooltip: 'Add one more',
          ),
        ],
      ),
    );
  }
}