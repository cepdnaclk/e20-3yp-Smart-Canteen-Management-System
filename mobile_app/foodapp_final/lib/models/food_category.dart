class FoodCategory {
  final int id;
  final String name;
  FoodCategory({required this.id, required this.name});
  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(id: json['id'], name: json['name']);
  }
}