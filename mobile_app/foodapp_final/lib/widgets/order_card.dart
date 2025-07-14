// import 'package:flutter/material.dart';
// import 'package:food_app/models/order.dart';
//
// class OrderCard extends StatelessWidget {
//   final Order order;
//   final VoidCallback? onAccept;
//   final VoidCallback? onComplete;
//   final VoidCallback? onDecline;
//   final VoidCallback? onDelete;
//
//   const OrderCard({
//     super.key,
//     required this.order,
//     this.onAccept,
//     this.onComplete,
//     this.onDecline,
//     this.onDelete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Order #${order.id}',
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Chip(
//                   label: Text(order.status),
//                   backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
//                   labelStyle: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const Divider(height: 20),
//             Text('Customer: ${order.customerEmail}'),
//             Text('Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
//             const SizedBox(height: 12),
//             const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
//             ...order.items.entries.map((entry) {
//               return Text('  • ${entry.key} (x${entry.value})');
//             }),
//             const SizedBox(height: 12),
//             if (onAccept != null || onComplete != null)
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: ElevatedButton(
//                   onPressed: onAccept ?? onComplete,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: onAccept != null ? Colors.green : Colors.blue,
//                   ),
//                   child: Text(onAccept != null ? 'Accept Order' : 'Mark as Completed'),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toUpperCase()) {
//       case 'PENDING':
//         return Colors.orange;
//       case 'ACCEPTED':
//         return Colors.blue;
//       case 'COMPLETED':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:food_app/models/order.dart';
//
// class OrderCard extends StatelessWidget {
//   final Order order;
//   final VoidCallback? onAccept;
//   final VoidCallback? onComplete;
//   final VoidCallback? onDecline;
//   final VoidCallback? onDelete;
//
//   const OrderCard({
//     super.key,
//     required this.order,
//     this.onAccept,
//     this.onComplete,
//     this.onDecline,
//     this.onDelete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Order #${order.id}',
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Chip(
//                   label: Text(order.status),
//                   backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
//                   labelStyle: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const Divider(height: 20),
//             Text('Customer: ${order.customerEmail}'),
//             Text('Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
//             const SizedBox(height: 12),
//             const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
//             // This assumes order.items is a Map<String, int>
//             ...order.items.entries.map((entry) {
//               return Padding(
//                 padding: const EdgeInsets.only(left: 8.0, top: 4.0),
//                 child: Text('• ${entry.key} (x${entry.value})'),
//               );
//             }),
//             const SizedBox(height: 12),
//             // --- FIX: Replaced old button logic with this new helper method ---
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// --- FIX: This new helper method builds the correct buttons based on the order's state ---
//   Widget _buildActionButtons() {
//     // PENDING orders will have onAccept and onDecline callbacks
//     if (onAccept != null && onDecline != null) {
//       return Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           TextButton.icon(
//             icon: const Icon(Icons.cancel_outlined),
//             label: const Text('Decline'),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             onPressed: onDecline,
//           ),
//           const SizedBox(width: 8),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.check),
//             label: const Text('Accept'),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             onPressed: onAccept,
//           ),
//         ],
//       );
//     }
//     // ACCEPTED orders will have an onComplete callback
//     else if (onComplete != null) {
//       return Align(
//         alignment: Alignment.centerRight,
//         child: ElevatedButton.icon(
//           icon: const Icon(Icons.local_shipping),
//           label: const Text('Mark as Completed'),
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//           onPressed: onComplete,
//         ),
//       );
//     }
//     // COMPLETED orders will have an onDelete callback
//     else if (onDelete != null) {
//       return Align(
//         alignment: Alignment.centerRight,
//         child: TextButton.icon(
//           icon: const Icon(Icons.delete_outline),
//           label: const Text('Clear from list'),
//           style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
//           onPressed: onDelete,
//         ),
//       );
//     }
//     // If no actions are available, return an empty widget
//     return const SizedBox.shrink();
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toUpperCase()) {
//       case 'PENDING':
//         return Colors.orange;
//       case 'ACCEPTED':
//         return Colors.blue;
//       case 'COMPLETED':
//         return Colors.green;
//       case 'DECLINED':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:food_app/models/order.dart';
// import 'package:food_app/providers/cart_provider.dart'; // ✨ ADD: Import CartProvider
// import 'package:provider/provider.dart'; // ✨ ADD: Import Provider package
//
// class OrderCard extends StatelessWidget {
//   final Order order;
//   final VoidCallback? onAccept;
//   final VoidCallback? onComplete;
//   final VoidCallback? onDecline;
//   final VoidCallback? onDelete;
//
//   const OrderCard({
//     super.key,
//     required this.order,
//     this.onAccept,
//     this.onComplete,
//     this.onDecline,
//     this.onDelete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // ✨ ADD: Get the CartProvider to look up item names
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Order #${order.id}',
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Chip(
//                   label: Text(order.status),
//                   backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
//                   labelStyle: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const Divider(height: 20),
//             Text('Customer: ${order.customerEmail}'),
//             Text('Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
//             const SizedBox(height: 12),
//             const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
//
//             // ✨ UPDATE: This section now looks up and displays item names
//             ...order.items.entries.map((entry) {
//               final itemName = cartProvider.getItemNameById(entry.key);
//               return Padding(
//                 padding: const EdgeInsets.only(left: 8.0, top: 4.0),
//                 child: Text('• $itemName (x${entry.value})'),
//               );
//             }),
//
//             const SizedBox(height: 12),
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     // PENDING orders will have onAccept and onDecline callbacks
//     if (onAccept != null && onDecline != null) {
//       return Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           TextButton.icon(
//             icon: const Icon(Icons.cancel_outlined),
//             label: const Text('Decline'),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             onPressed: onDecline,
//           ),
//           const SizedBox(width: 8),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.check),
//             label: const Text('Accept'),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             onPressed: onAccept,
//           ),
//         ],
//       );
//     }
//     // ACCEPTED orders will have an onComplete callback
//     else if (onComplete != null) {
//       return Align(
//         alignment: Alignment.centerRight,
//         child: ElevatedButton.icon(
//           icon: const Icon(Icons.local_shipping),
//           label: const Text('Mark as Completed'),
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//           onPressed: onComplete,
//         ),
//       );
//     }
//     // COMPLETED orders will have an onDelete callback
//     else if (onDelete != null) {
//       return Align(
//         alignment: Alignment.centerRight,
//         child: TextButton.icon(
//           icon: const Icon(Icons.delete_outline),
//           label: const Text('Clear from list'),
//           style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
//           onPressed: onDelete,
//         ),
//       );
//     }
//     // If no actions are available, return an empty widget
//     return const SizedBox.shrink();
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toUpperCase()) {
//       case 'PENDING':
//         return Colors.orange;
//       case 'ACCEPTED':
//         return Colors.blue;
//       case 'COMPLETED':
//         return Colors.green;
//       case 'DECLINED':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:food_app/models/order.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;
  final VoidCallback? onDecline;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onComplete,
    this.onDecline,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  label: Text(order.status),
                  backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
                  labelStyle: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('Customer: ${order.customerEmail}'),
            Text('Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),

            ...order.items.entries.map((entry) {
              final itemName = cartProvider.getItemNameById(entry.key);
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Text('• $itemName (x${entry.value})'),
              );
            }),

            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // THIS IS THE MODIFIED SECTION
  Widget _buildActionButtons() {
    if (onAccept != null && onDecline != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ✨ CHANGED: This is now an ElevatedButton.icon
          ElevatedButton.icon(
            icon: const Icon(Icons.close), // Changed icon for better look
            label: const Text('Decline'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Set background to red
              foregroundColor: Colors.white, // Ensure text is white
            ),
            onPressed: onDecline,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: onAccept,
          ),
        ],
      );
    } else if (onComplete != null) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.local_shipping),
          label: const Text('Mark as Completed'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, foregroundColor: Colors.white),
          onPressed: onComplete,
        ),
      );
    } else if (onDelete != null) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear from list'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          onPressed: onDelete,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'DECLINED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}