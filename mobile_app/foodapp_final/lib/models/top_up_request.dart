// lib/models/top_up_request.dart

class TopUpRequest {
  final int id;
  final String customerUsername;
  final String customerEmail;
  final double amount;
  final String pin;
  final String status;

  TopUpRequest({
    required this.id,
    required this.customerUsername,
    required this.customerEmail,
    required this.amount,
    required this.pin,
    required this.status,
  });

  factory TopUpRequest.fromJson(Map<String, dynamic> json) {
    return TopUpRequest(
      id: json['id'] ?? 0,
      customerUsername: json['customerUsername'] ?? 'Unknown User',
      customerEmail: json['customerEmail'] ?? 'N/A',
      amount: (json['amount'] as num).toDouble(),
      pin: json['pin'] ?? '****',
      status: json['status'] ?? 'UNKNOWN',
    );
  }
}