


// lib/screens/customer/budget_dashboard.dart

// lib/screens/customer/budget_dashboard.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/top_up_request.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:http/http.dart' as http;
//
// class BudgetDashboard extends StatefulWidget {
//   const BudgetDashboard({super.key});
//
//   @override
//   State<BudgetDashboard> createState() => _BudgetDashboardState();
// }
//
// class _BudgetDashboardState extends State<BudgetDashboard> {
//   final storage = const FlutterSecureStorage();
//   double _balance = 0.0;
//   bool _isLoadingBalance = true;
//   List<TopUpRequest> _requests = [];
//   bool _isLoadingRequests = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }
//
//   Future<void> _fetchData() async {
//     await Future.wait([_fetchBalance(), _fetchRequests()]);
//   }
//
//   Future<void> _fetchBalance() async {
//     if (!mounted) return;
//     setState(() => _isLoadingBalance = true);
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.topupBalance),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       if (mounted && response.statusCode == 200) {
//         setState(() => _balance = double.parse(response.body));
//       }
//     } catch (e) {
//       // Handle error
//     } finally {
//       if (mounted) setState(() => _isLoadingBalance = false);
//     }
//   }
//
//   Future<void> _fetchRequests() async {
//     if (!mounted) return;
//     setState(() => _isLoadingRequests = true);
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.myTopupRequests),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       if (mounted && response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         setState(() {
//           _requests = data.map((json) => TopUpRequest.fromJson(json)).toList();
//         });
//       }
//     } catch (e) {
//       // Handle error
//     } finally {
//       if (mounted) setState(() => _isLoadingRequests = false);
//     }
//   }
//
//   void _showTopUpDialog(BuildContext context) {
//     final amountController = TextEditingController();
//     final formKey = GlobalKey<FormState>();
//
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Request Top-Up'),
//         content: Form(
//           key: formKey,
//           child: TextFormField(
//             controller: amountController,
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs. '),
//             validator: (value) {
//               if (value == null || value.isEmpty) return 'Please enter an amount';
//               if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid amount';
//               return null;
//             },
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               if (formKey.currentState?.validate() == true) {
//                 final amount = double.parse(amountController.text);
//                 Navigator.pop(dialogContext);
//                 _sendTopUpRequest(amount);
//               }
//             },
//             child: const Text('Send Request'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _sendTopUpRequest(double amount) async {
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.topupRequest),
//         headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
//         body: jsonEncode({'amount': amount}),
//       );
//
//       if (!mounted) return;
//
//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Your top-up request has been sent.', isSuccess: true);
//         _fetchData();
//       } else {
//         String errorMessage = 'Could not send request.';
//         if (response.body.isNotEmpty) {
//           try {
//             final errorBody = jsonDecode(response.body);
//             errorMessage = errorBody['message'] ?? errorMessage;
//           } catch (e) { /* Ignore parsing error */ }
//         }
//         NotificationUtils.showAnimatedPopup(context, title: 'Failed', message: errorMessage, isSuccess: false);
//       }
//     } catch (e) {
//       if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'An error occurred.', isSuccess: false);
//     }
//   }
//
//   Future<void> _deleteRequest(int requestId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Confirm Deletion'),
//         content: const Text('Are you sure you want to delete this pending request?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );
//
//     if (confirm != true) return;
//
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       final response = await http.delete(
//         Uri.parse('${ApiConstants.baseUrl}${ApiConstants.topupRequest}/$requestId'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (!mounted) return;
//
//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Request deleted.', isSuccess: true);
//         _fetchData();
//       } else {
//         String errorMessage = 'Could not delete request.';
//         if (response.body.isNotEmpty) {
//           try {
//             final errorBody = jsonDecode(response.body);
//             errorMessage = errorBody['message'] ?? errorMessage;
//           } catch (e) { /* Ignore parsing error */ }
//         }
//         NotificationUtils.showAnimatedPopup(context, title: 'Failed', message: errorMessage, isSuccess: false);
//       }
//     } catch (e) {
//       if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'An error occurred.', isSuccess: false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Budget"),
//         actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData)],
//       ),
//       body: Column(
//         children: [
//           _buildBalanceCard(),
//           const Padding(
//             padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
//             child: Row(
//               children: [
//                 Icon(Icons.history, color: Colors.grey),
//                 SizedBox(width: 8),
//                 Text("Your Top-Up Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//           Expanded(child: _buildRequestsList()),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showTopUpDialog(context),
//         label: const Text('Request Top-Up'),
//         icon: const Icon(Icons.add),
//       ),
//     );
//   }
//
//   Widget _buildBalanceCard() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         width: double.infinity,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           gradient: LinearGradient(
//             colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("CURRENT BALANCE", style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.5)),
//             const SizedBox(height: 10),
//             if (_isLoadingBalance)
//               const SizedBox(height: 40, child: CircularProgressIndicator(color: Colors.white))
//             else
//               Text(
//                 "Rs. ${_balance.toStringAsFixed(2)}",
//                 style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRequestsList() {
//     if (_isLoadingRequests) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_requests.isEmpty) {
//       return const Center(child: Text("You have no top-up requests."));
//     }
//     return ListView.builder(
//       padding: const EdgeInsets.only(top: 8),
//       itemCount: _requests.length,
//       itemBuilder: (context, index) {
//         final req = _requests[index];
//         final status = req.status.toUpperCase();
//         final statusColor = status == 'PENDING' ? Colors.orange : (status == 'APPROVED' ? Colors.green : Colors.red);
//         final statusIcon = status == 'PENDING' ? Icons.hourglass_top : (status == 'APPROVED' ? Icons.check_circle : Icons.cancel);
//
//         return Card(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           child: ListTile(
//             leading: Icon(statusIcon, color: statusColor),
//             title: Text("Amount: Rs. ${req.amount.toStringAsFixed(2)}"),
//             subtitle: Text("PIN: ${req.pin} | Status: $status"),
//             trailing: status == 'PENDING'
//                 ? IconButton(
//               icon: const Icon(Icons.delete, color: Colors.redAccent),
//               tooltip: 'Delete Request',
//               onPressed: () => _deleteRequest(req.id),
//             )
//                 : null,
//           ),
//         );
//       },
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/top_up_request.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;

class BudgetDashboard extends StatefulWidget {
  const BudgetDashboard({super.key});

  @override
  State<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends State<BudgetDashboard> {
  final storage = const FlutterSecureStorage();
  double _balance = 0.0;
  bool _isLoadingBalance = true;
  List<TopUpRequest> _requests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchBalance(), _fetchRequests()]);
  }

  Future<void> _fetchBalance() async {
    if (!mounted) return;
    setState(() => _isLoadingBalance = true);
    try {
      final token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.topupBalance),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted && response.statusCode == 200) {
        setState(() => _balance = double.parse(response.body));
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingRequests = true);
    try {
      final token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.myTopupRequests),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _requests = data.map((json) => TopUpRequest.fromJson(json)).toList();
          // Sort by id in descending order (latest first)
          _requests.sort((a, b) => b.id.compareTo(a.id));
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  void _showTopUpDialog(BuildContext context) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Top-Up'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs. '),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an amount';
              if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid amount';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final amount = double.parse(amountController.text);
                Navigator.pop(dialogContext);
                _sendTopUpRequest(amount);
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTopUpRequest(double amount) async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.topupRequest),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Your top-up request has been sent.', isSuccess: true);
        _fetchData();
      } else {
        String errorMessage = 'Could not send request.';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) { /* Ignore parsing error */ }
        }
        NotificationUtils.showAnimatedPopup(context, title: 'Failed', message: errorMessage, isSuccess: false);
      }
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'An error occurred.', isSuccess: false);
    }
  }

  Future<void> _deleteRequest(int requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this pending request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.topupRequest}/$requestId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Request deleted.', isSuccess: true);
        _fetchData();
      } else {
        String errorMessage = 'Could not delete request.';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) { /* Ignore parsing error */ }
        }
        NotificationUtils.showAnimatedPopup(context, title: 'Failed', message: errorMessage, isSuccess: false);
      }
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'An error occurred.', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Budget"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData)],
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 8),
                Text("Your Top-Up Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: _buildRequestsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTopUpDialog(context),
        label: const Text('Request Top-Up'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("CURRENT BALANCE", style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            if (_isLoadingBalance)
              const SizedBox(height: 40, child: CircularProgressIndicator(color: Colors.white))
            else
              Text(
                "Rs. ${_balance.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requests.isEmpty) {
      return const Center(child: Text("You have no top-up requests."));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        final status = req.status.toUpperCase();
        final statusColor = status == 'PENDING' ? Colors.orange : (status == 'APPROVED' ? Colors.green : Colors.red);
        final statusIcon = status == 'PENDING' ? Icons.hourglass_top : (status == 'APPROVED' ? Icons.check_circle : Icons.cancel);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Text("Amount: Rs. ${req.amount.toStringAsFixed(2)}"),
            subtitle: Text("PIN: ${req.pin} | Status: $status"),
            trailing: status == 'PENDING'
                ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Delete Request',
              onPressed: () => _deleteRequest(req.id),
            )
                : null,
          ),
        );
      },
    );
  }
}
