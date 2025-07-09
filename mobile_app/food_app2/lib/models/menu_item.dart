class MenuItem {
  final int id;
  final String name;
  final double price;
  final double costPrice;
  final String imagePath;
  final int categoryId;
  final String? categoryName;
  final int stock;

  MenuItem({
    required this.id, required this.name, required this.price,
    required this.costPrice, required this.imagePath, required this.categoryId,
    this.categoryName, required this.stock,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'], name: json['name'],
    price: (json['price'] as num).toDouble(),
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    imagePath: json['imagePath'] ?? '', categoryId: json['categoryId'] ?? 0,
    categoryName: json['categoryName'], stock: json['stock'] ?? 0,
  );
}