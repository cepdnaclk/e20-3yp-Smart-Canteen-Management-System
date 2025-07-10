// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/order.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:food_app/widgets/order_card.dart';
// import 'package:http/http.dart' as http;
//
// class OrderManagementScreen extends StatefulWidget {
//   const OrderManagementScreen({super.key});
//
//   @override
//   State<OrderManagementScreen> createState() => _OrderManagementScreenState();
// }
//
// class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final _storage = const FlutterSecureStorage();
//
//   final GlobalKey<AnimatedListState> _pendingListKey = GlobalKey<AnimatedListState>();
//   final GlobalKey<AnimatedListState> _acceptedListKey = GlobalKey<AnimatedListState>();
//
//   List<Order> _pendingOrders = [];
//   List<Order> _acceptedOrders = [];
//   List<Order> _completedOrders = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _tabController.addListener(() {
//       if (_tabController.indexIsChanging) {
//         _fetchAllOrders();
//       }
//     });
//     _fetchAllOrders();
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchAllOrders() async {
//     setState(() => _isLoading = true);
//     await Future.wait([
//       _fetchOrders('pending'),
//       _fetchOrders('accepted'),
//       _fetchOrders('completed'),
//     ]);
//     if (mounted) setState(() => _isLoading = false);
//   }
//
//   Future<void> _fetchOrders(String status) async {
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.merchantOrdersByStatus + status),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         final orders = data.map((json) => Order.fromJson(json)).toList();
//         if (mounted) {
//           setState(() {
//             if (status == 'pending') _pendingOrders = orders;
//             if (status == 'accepted') _acceptedOrders = orders;
//             if (status == 'completed') _completedOrders = orders;
//           });
//         }
//       }
//     } catch (e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Could not fetch orders.", isSuccess: false);
//     }
//   }
//
//   Future<void> _acceptOrder(Order order, int index) async {
//     _pendingListKey.currentState?.removeItem(
//       index,
//           (context, animation) => SizeTransition(
//         sizeFactor: animation,
//         child: FadeTransition(
//           opacity: animation,
//           child: OrderCard(order: order),
//         ),
//       ),
//       duration: const Duration(milliseconds: 500),
//     );
//     _pendingOrders.removeAt(index);
//
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.acceptOrder}${order.id}/accept');
//       final response = await http.put(url, headers: {'Authorization': 'Bearer $token'});
//
//       if(response.statusCode == 200) {
//         if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Success!', message: 'Order #${order.id} has been accepted.', isSuccess: true);
//       } else {
//         throw Exception('Failed to accept order');
//       }
//     } catch(e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to update order status.', isSuccess: false);
//       _fetchAllOrders();
//     }
//   }
//
//   // In lib/screens/merchant/order_management_screen.dart
//
//   Future<void> _completeOrder(Order order, int index) async {
//     // This animates the card out of the "Accepted" list immediately for a responsive feel.
//     _acceptedListKey.currentState?.removeItem(
//       index,
//           (context, animation) => SizeTransition(
//         sizeFactor: animation,
//         child: FadeTransition(
//           opacity: animation,
//           child: OrderCard(order: order),
//         ),
//       ),
//       duration: const Duration(milliseconds: 500),
//     );
//     _acceptedOrders.removeAt(index);
//
//     // --- API Call Logic Added ---
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.completeOrder}${order.id}/complete');
//
//       final response = await http.put(
//         url,
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           NotificationUtils.showAnimatedPopup(
//             context,
//             title: 'Done!',
//             message: 'Order #${order.id} is marked as complete.',
//             isSuccess: true,
//           );
//           // No need to call _fetchAllOrders() on success, as the item is already removed from the UI.
//           // The completed list will update the next time the user switches to that tab.
//         } else {
//           throw Exception('Failed to complete order on the server.');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         NotificationUtils.showAnimatedPopup(
//           context,
//           title: 'Error',
//           message: 'Failed to update order status. Please refresh and try again.',
//           isSuccess: false,
//         );
//         // Because the API call failed, we refresh the lists to revert the UI to a consistent state.
//         _fetchAllOrders();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Order Management'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Pending'),
//             Tab(text: 'Accepted'),
//             Tab(text: 'Completed'),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//         controller: _tabController,
//         children: [
//           _buildAnimatedOrderList(_pendingListKey, _pendingOrders, onAccept: _acceptOrder),
//           _buildAnimatedOrderList(_acceptedListKey, _acceptedOrders, onComplete: _completeOrder),
//           _buildOrderList(_completedOrders),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _fetchAllOrders,
//         child: const Icon(Icons.refresh),
//         tooltip: 'Refresh Orders',
//       ),
//     );
//   }
//
//   Widget _buildAnimatedOrderList(
//       GlobalKey<AnimatedListState> key,
//       List<Order> orders,
//       {Function(Order, int)? onAccept, Function(Order, int)? onComplete}
//       ) {
//     if (orders.isEmpty) {
//       return Center(child: Text('No orders in this category.', style: TextStyle(color: Colors.grey.shade600)));
//     }
//     return AnimatedList(
//       key: key,
//       initialItemCount: orders.length,
//       itemBuilder: (context, index, animation) {
//         final order = orders[index];
//         return SizeTransition(
//           sizeFactor: animation,
//           child: OrderCard(
//             order: order,
//             onAccept: onAccept != null ? () => onAccept(order, index) : null,
//             onComplete: onComplete != null ? () => onComplete(order, index) : null,
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildOrderList(List<Order> orders) {
//     if (orders.isEmpty) {
//       return Center(child: Text('No orders in this category.', style: TextStyle(color: Colors.grey.shade600)));
//     }
//     return ListView.builder(
//       itemCount: orders.length,
//       itemBuilder: (context, index) {
//         final order = orders[index];
//         return OrderCard(order: order);
//       },
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/order.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/order_card.dart';
import 'package:http/http.dart' as http;

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();

  final GlobalKey<AnimatedListState> _pendingListKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _acceptedListKey = GlobalKey<AnimatedListState>();

  List<Order> _pendingOrders = [];
  List<Order> _acceptedOrders = [];
  List<Order> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchOrders('pending'),
        _fetchOrders('accepted'),
        _fetchOrders('completed'),
      ]);
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Could not fetch orders.", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrders(String status) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.merchantOrdersByStatus}$status');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (mounted && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final orders = data.map((json) => Order.fromJson(json)).toList();
        setState(() {
          if (status == 'pending') _pendingOrders = orders;
          if (status == 'accepted') _acceptedOrders = orders;
          if (status == 'completed') _completedOrders = orders;
        });
      } else {
        throw Exception('Failed to load $status orders');
      }
    } catch (e) {
      // Let the main fetch handler show the error
    }
  }

  // FIX: Using a single, generic function to handle all status updates, taken from your older, better code.
  Future<void> _updateOrderStatus(Order order, int index, String action) async {
    // Optimistically remove the item from its current list for a fast UI response
    if (action == 'accept' || action == 'decline') {
      _pendingListKey.currentState?.removeItem(index, (context, animation) => _buildRemovedItem(order, animation));
      _pendingOrders.removeAt(index);
    } else if (action == 'complete') {
      _acceptedListKey.currentState?.removeItem(index, (context, animation) => _buildRemovedItem(order, animation));
      _acceptedOrders.removeAt(index);
    }

    try {
      final token = await _storage.read(key: 'jwt_token');
      // Assumes your backend supports /api/orders/{id}/{action} like 'accept', 'decline', 'complete'
      final url = Uri.parse('${ApiConstants.baseUrl}/api/orders/${order.id}/$action');
      final response = await http.put(url, headers: {'Authorization': 'Bearer $token'});

      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(context, title: 'Success!', message: 'Order #${order.id} has been updated.', isSuccess: true);
          // On success, we don't need to do a full reload. The optimistic removal handles the UI.
          // The other lists will be updated naturally when the user switches tabs or pulls to refresh.
        } else {
          throw Exception('Failed to $action order');
        }
      }
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to update order status. Reverting change.', isSuccess: false);
      // If the API call fails, we must do a full refresh to bring the UI back to a consistent state.
      _fetchAllOrders();
    }
  }

  // Helper for the remove animation
  Widget _buildRemovedItem(Order order, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: OrderCard(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Accepted'),
            Tab(icon: Icon(Icons.history), text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // FIX: Pass both onAccept and onDecline callbacks to the pending orders list
          _buildAnimatedOrderList(
            _pendingListKey,
            _pendingOrders,
            onAccept: (order, index) => _updateOrderStatus(order, index, 'accept'),
            onDecline: (order, index) => _updateOrderStatus(order, index, 'decline'),
          ),
          _buildAnimatedOrderList(
            _acceptedListKey,
            _acceptedOrders,
            onComplete: (order, index) => _updateOrderStatus(order, index, 'complete'),
          ),
          _buildOrderList(_completedOrders),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAllOrders,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Orders',
      ),
    );
  }

  // FIX: Updated the signature to accept an onDecline callback
  Widget _buildAnimatedOrderList(
      GlobalKey<AnimatedListState> key,
      List<Order> orders, {
        Function(Order, int)? onAccept,
        Function(Order, int)? onComplete,
        Function(Order, int)? onDecline,
      }) {
    if (orders.isEmpty) {
      return Center(
          child: Text('No orders in this category.',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return AnimatedList(
      key: key,
      initialItemCount: orders.length,
      itemBuilder: (context, index, animation) {
        final order = orders[index];
        return SizeTransition(
          sizeFactor: animation,
          child: OrderCard(
            order: order,
            onAccept: onAccept != null ? () => onAccept(order, index) : null,
            onDecline: onDecline != null ? () => onDecline(order, index) : null,
            onComplete: onComplete != null ? () => onComplete(order, index) : null,
          ),
        );
      },
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
          child: Text('No orders in this category.',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(order: order); // Completed orders don't need actions
      },
    );
  }
}