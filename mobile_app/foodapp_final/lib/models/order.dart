class Order {
  final String id;
  final String customerEmail;
  final double totalAmount;
  final String status;
  final Map<String, int> items;
  final DateTime orderTime;

  Order({
    required this.id, required this.customerEmail, required this.totalAmount,
    required this.status, required this.items, required this.orderTime,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(), customerEmail: json['email'] ?? 'Unknown',
      totalAmount: (json['totalAmount'] as num).toDouble(), status: json['status'] ?? 'UNKNOWN',
      items: Map<String, int>.from(json['items']), orderTime: DateTime.parse(json['orderTime']),
    );
  }
}