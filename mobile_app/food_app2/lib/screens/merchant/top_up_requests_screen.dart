import 'package:flutter/material.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TopUpRequest {
  final String id;
  final String customerEmail;
  final double amount;
  final String pin;

  TopUpRequest({required this.id, required this.customerEmail, required this.amount, required this.pin});

  factory TopUpRequest.fromJson(Map<String, dynamic> json) {
    return TopUpRequest(
      id: json['id'].toString(),
      customerEmail: json['customer_id'] ?? 'N/A',
      amount: (json['amount'] as num).toDouble(),
      pin: json['pin'] ?? '****',
    );
  }
}

class TopUpRequestsScreen extends StatefulWidget {
  const TopUpRequestsScreen({super.key});

  @override
  State<TopUpRequestsScreen> createState() => _TopUpRequestsScreenState();
}

class _TopUpRequestsScreenState extends State<TopUpRequestsScreen> {
  late Future<List<TopUpRequest>> _requestsFuture;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchPendingRequests();
  }

  Future<List<TopUpRequest>> _fetchPendingRequests() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.pendingTopups),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TopUpRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load requests');
    }
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = _fetchPendingRequests();
    });
  }

  Future<void> _respondToRequest(String requestId, bool approve, String customerPin) async {
    final String? enteredPin = await _showPinDialog(customerPin);

    if (enteredPin == null) return; // User cancelled

    if (enteredPin != customerPin) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: "Incorrect PIN", message: "The PIN you entered does not match the customer's PIN.", isSuccess: false);
      return;
    }

    final token = await _storage.read(key: 'jwt_token');
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.respondToTopup}$requestId?approve=$approve&pin=$enteredPin');

    try {
      final response = await http.post(url, headers: {'Authorization': 'Bearer $token'});
      if (mounted) {
        if (response.statusCode == 200) {
          NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Request has been ${approve ? 'approved' : 'rejected'}.", isSuccess: true);
          _refreshRequests();
        } else {
          final error = jsonDecode(response.body)['error'] ?? "An unknown error occurred.";
          NotificationUtils.showAnimatedPopup(context, title: "Failed", message: error, isSuccess: false);
        }
      }
    } catch (e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Could not connect to the server.", isSuccess: false);
    }
  }

  Future<String?> _showPinDialog(String customerPin) async {
    final pinController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Customer PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please ask the customer for their 4-digit PIN to confirm this transaction. The required PIN is $customerPin.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: '4-Digit PIN', border: OutlineInputBorder(), counterText: ''),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(pinController.text), child: const Text('Confirm')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top-Up Requests')),
      body: RefreshIndicator(
        onRefresh: () async => _refreshRequests(),
        child: FutureBuilder<List<TopUpRequest>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No pending top-up requests.'));
            }
            final requests = snapshot.data!;
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${request.customerEmail}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(height: 20),
                        Text('Amount: Rs. ${request.amount.toStringAsFixed(2)}'),
                        Text('Customer PIN: ${request.pin}', style: const TextStyle(color: Colors.blueGrey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _respondToRequest(request.id, false, request.pin),
                              child: const Text('REJECT', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _respondToRequest(request.id, true, request.pin),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('APPROVE'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}