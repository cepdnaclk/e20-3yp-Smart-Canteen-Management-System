import 'dart:convert';

// This is the main report object
class SalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final int totalOrders;
  final int totalItemsSold;
  final ItemSaleInfo? mostSoldItem;
  final ItemSaleInfo? leastSoldItem;
  final List<ItemSaleInfo> itemSales;

  SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItemsSold,
    this.mostSoldItem,
    this.leastSoldItem,
    required this.itemSales,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    startDate: DateTime.parse(json["startDate"]),
    endDate: DateTime.parse(json["endDate"]),
    totalRevenue: (json["totalRevenue"] as num).toDouble(),
    totalOrders: json["totalOrders"],
    totalItemsSold: json["totalItemsSold"],
    mostSoldItem: json["mostSoldItem"] == null ? null : ItemSaleInfo.fromJson(json["mostSoldItem"]),
    leastSoldItem: json["leastSoldItem"] == null ? null : ItemSaleInfo.fromJson(json["leastSoldItem"]),
    itemSales: List<ItemSaleInfo>.from(json["itemSales"].map((x) => ItemSaleInfo.fromJson(x))),
  );
}

// This represents a single item in the report's breakdown
class ItemSaleInfo {
  final int menuItemId;
  final String itemName;
  final int quantitySold;
  final double totalRevenue;

  ItemSaleInfo({
    required this.menuItemId,
    required this.itemName,
    required this.quantitySold,
    required this.totalRevenue,
  });

  factory ItemSaleInfo.fromJson(Map<String, dynamic> json) => ItemSaleInfo(
    menuItemId: json["menuItemId"],
    itemName: json["itemName"],
    quantitySold: json["quantitySold"],
    totalRevenue: (json["totalRevenue"] as num).toDouble(),
  );
}