// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/order.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:lottie/lottie.dart';
//
// class OrderHistoryScreen extends StatefulWidget {
//   const OrderHistoryScreen({super.key});
//
//   @override
//   State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
// }
//
// class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
//   final _storage = const FlutterSecureStorage();
//   late Future<List<Order>> _ordersFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _ordersFuture = _fetchMyOrders();
//   }
//
//   Future<void> _refreshOrders() async {
//     setState(() {
//       _ordersFuture = _fetchMyOrders();
//     });
//   }
//
//   Future<List<Order>> _fetchMyOrders() async {
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.myOrders),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         final orders = data.map((json) => Order.fromJson(json)).toList();
//         // Sort orders by most recent first
//         orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
//         return orders;
//       } else {
//         throw Exception('Failed to load orders');
//       }
//     } catch (e) {
//       throw Exception('Error fetching orders: $e');
//     }
//   }
//
//   Future<void> _cancelOrder(String orderId) async {
//     // Confirmation Dialog
//     final bool? confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Cancel Order?'),
//         content: const Text('Are you sure you want to cancel this pending order?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//
//     if (confirm != true) return;
//
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final url = Uri.parse('${ApiConstants.baseUrl}/api/orders/my-history/$orderId/cancel');
//       final response = await http.put(
//         url,
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Order #$orderId has been cancelled.', isSuccess: true);
//           _refreshOrders();
//         } else {
//           NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to cancel order.', isSuccess: false);
//         }
//       }
//     } catch (e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'An error occurred.', isSuccess: false);
//     }
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toUpperCase()) {
//       case 'PENDING': return Colors.orange;
//       case 'ACCEPTED': return Colors.blue;
//       case 'COMPLETED': return Colors.green;
//       case 'CANCELLED': return Colors.red;
//       default: return Colors.grey;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Orders'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshOrders,
//         child: FutureBuilder<List<Order>>(
//           future: _ordersFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }
//             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Lottie.asset('assets/animations/empty_cart.json', width: 200),
//                     const Text('You have not placed any orders yet.', style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               );
//             }
//
//             final orders = snapshot.data!;
//             return AnimationLimiter(
//               child: ListView.builder(
//                 itemCount: orders.length,
//                 itemBuilder: (context, index) {
//                   final order = orders[index];
//                   return AnimationConfiguration.staggeredList(
//                     position: index,
//                     duration: const Duration(milliseconds: 375),
//                     child: SlideAnimation(
//                       verticalOffset: 50.0,
//                       child: FadeInAnimation(
//                         child: Card(
//                           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                           elevation: 2,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           child: ExpansionTile(
//                             leading: Icon(Icons.receipt_long, color: _getStatusColor(order.status)),
//                             title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
//                             subtitle: Text('${DateFormat.yMMMd().format(order.orderTime)} - Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
//                             trailing: Chip(
//                               label: Text(order.status),
//                               backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
//                               labelStyle: TextStyle(color: _getStatusColor(order.status)),
//                             ),
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(left: 32),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
//                                     ...order.items.entries.map((entry) => Text('  • ${entry.key} (x${entry.value})')),
//                                     const SizedBox(height: 8),
//                                     Text('Placed at: ${DateFormat.jm().format(order.orderTime.toLocal())}'),
//                                     // ADDED: Show cancel button for pending orders
//                                     if (order.status.toUpperCase() == 'PENDING')
//                                       Padding(
//                                         padding: const EdgeInsets.only(top: 8.0),
//                                         child: Align(
//                                           alignment: Alignment.centerRight,
//                                           child: TextButton.icon(
//                                             onPressed: () => _cancelOrder(order.id),
//                                             icon: const Icon(Icons.cancel, color: Colors.red),
//                                             label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/order.dart';
import 'package:food_app/providers/cart_provider.dart'; // ✨ ADD: Import CartProvider
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart'; // ✨ ADD: Import Provider package

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchMyOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchMyOrders();
    });
  }

  Future<List<Order>> _fetchMyOrders() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.myOrders),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final orders = data.map((json) => Order.fromJson(json)).toList();
        orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
        return orders;
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this pending order?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      final url = Uri.parse('${ApiConstants.baseUrl}/api/orders/my-history/$orderId/cancel');
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Order #$orderId has been cancelled.', isSuccess: true);
          _refreshOrders();
        } else {
          NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to cancel order.', isSuccess: false);
        }
      }
    } catch (e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'An error occurred.', isSuccess: false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✨ ADD: Get the CartProvider instance here
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/animations/empty_cart.json', width: 200),
                    const Text('You have not placed any orders yet.', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }

            final orders = snapshot.data!;
            return AnimationLimiter(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: Icon(Icons.receipt_long, color: _getStatusColor(order.status)),
                            title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${DateFormat.yMMMd().format(order.orderTime)} - Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
                            trailing: Chip(
                              label: Text(order.status),
                              backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
                              labelStyle: TextStyle(color: _getStatusColor(order.status)),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(left: 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    // ✨ UPDATE: Use the provider to look up the item name
                                    ...order.items.entries.map((entry) {
                                      final itemName = cartProvider.getItemNameById(entry.key);
                                      return Text('  • $itemName (x${entry.value})');
                                    }),
                                    const SizedBox(height: 8),
                                    Text('Placed at: ${DateFormat.jm().format(order.orderTime.toLocal())}'),
                                    if (order.status.toUpperCase() == 'PENDING')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () => _cancelOrder(order.id),
                                            icon: const Icon(Icons.cancel, color: Colors.red),
                                            label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}