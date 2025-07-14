// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// // import 'package:food_app/api/api_constants.dart';
// // import 'package:food_app/models/food_category.dart';
// // import 'package:food_app/models/menu_item.dart';
// // import 'package:food_app/utils/notification_utils.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:image_picker/image_picker.dart';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // import 'package:shimmer/shimmer.dart';
// //
// // class ManageMenuScreen extends StatefulWidget {
// //   const ManageMenuScreen({super.key});
// //
// //   @override
// //   State<ManageMenuScreen> createState() => _ManageMenuScreenState();
// // }
// //
// // class _ManageMenuScreenState extends State<ManageMenuScreen> with SingleTickerProviderStateMixin {
// //   final _storage = const FlutterSecureStorage();
// //   List<FoodCategory> _categories = [];
// //   List<MenuItem> _foodItems = [];
// //   bool _isLoading = true;
// //   TabController? _tabController;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadData();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _tabController?.dispose();
// //     super.dispose();
// //   }
// //
// //   // --- DATA LOADING & API METHODS ---
// //   Future<void> _loadData() async {
// //     setState(() => _isLoading = true);
// //     await Future.wait([_loadCategories(), _loadFoodItems()]);
// //     _updateTabController();
// //     if (mounted) setState(() => _isLoading = false);
// //   }
// //
// //   Future<void> _loadCategories() async {
// //     try {
// //       final token = await _storage.read(key: 'jwt_token');
// //       final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Authorization': 'Bearer $token'});
// //       if (response.statusCode == 200) {
// //         final List data = jsonDecode(response.body);
// //         _categories = data.map((json) => FoodCategory.fromJson(json)).toList();
// //       }
// //     } catch (e) {
// //       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not load categories.', isSuccess: false);
// //     }
// //   }
// //
// //   Future<void> _loadFoodItems() async {
// //     try {
// //       final token = await _storage.read(key: 'jwt_token');
// //       final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems), headers: {'Authorization': 'Bearer $token'});
// //       if (response.statusCode == 200) {
// //         final List data = jsonDecode(response.body);
// //         _foodItems = data.map((json) => MenuItem.fromJson(json)).toList();
// //       }
// //     } catch (e) {
// //       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not load menu items.', isSuccess: false);
// //     }
// //   }
// //
// //   void _updateTabController() {
// //     if (_categories.isEmpty) {
// //       _tabController?.dispose();
// //       _tabController = null;
// //     } else if (_tabController?.length != _categories.length) {
// //       final oldIndex = _tabController?.index ?? 0;
// //       _tabController?.dispose();
// //       _tabController = TabController(length: _categories.length, vsync: this, initialIndex: oldIndex < _categories.length ? oldIndex : 0);
// //     }
// //     setState(() {});
// //   }
// //
// //   Future<String?> _uploadImage(XFile imageFile) async {
// //     try {
// //       final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.baseUrl + ApiConstants.uploads));
// //       request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
// //       final response = await request.send();
// //       if (response.statusCode == 200) {
// //         final responseData = await response.stream.bytesToString();
// //         return jsonDecode(responseData)['filePath'];
// //       }
// //     } catch (e) {
// //       return null;
// //     }
// //     return null;
// //   }
// //
// //   Future<void> _saveMenuItem({MenuItem? item, required String name, required double price, required double costPrice, required int stock, required int categoryId, XFile? image}) async {
// //     String? imagePath = item?.imagePath;
// //     if (image != null) {
// //       final uploadedPath = await _uploadImage(image);
// //       if (uploadedPath == null) {
// //         NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Image upload failed. Item not saved.", isSuccess: false);
// //         return;
// //       }
// //       imagePath = uploadedPath;
// //     }
// //     if (imagePath == null && item == null) {
// //       NotificationUtils.showAnimatedPopup(context, title: "Error", message: "An image is required for new items.", isSuccess: false);
// //       return;
// //     }
// //     final body = json.encode({'id': item?.id, 'name': name, 'price': price, 'costPrice': costPrice, 'stock': stock, 'categoryId': categoryId, 'imagePath': imagePath});
// //     final token = await _storage.read(key: 'jwt_token');
// //     final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
// //     final url = item == null ? Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems) : Uri.parse('${ApiConstants.baseUrl}${ApiConstants.menuItems}/${item.id}');
// //     final response = item == null ? await http.post(url, headers: headers, body: body) : await http.put(url, headers: headers, body: body);
// //     if (mounted) {
// //       if (response.statusCode == 200) {
// //         NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Menu item has been saved.", isSuccess: true);
// //         _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Failed to save item. ${response.body}", isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _deleteMenuItem(MenuItem item) async {
// //     final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Item?'), content: Text('Are you sure you want to delete "${item.name}"?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
// //     if (confirm != true) return;
// //     final token = await _storage.read(key: 'jwt_token');
// //     final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.menuItems}/${item.id}'), headers: {'Authorization': 'Bearer $token'});
// //     if (mounted) {
// //       if (response.statusCode == 204 || response.statusCode == 200) {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: '${item.name} has been deleted.', isSuccess: true);
// //         _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete item. It might be in use.', isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _addCategory(String name) async {
// //     final token = await _storage.read(key: 'jwt_token');
// //     final response = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'name': name, 'description': 'A new Category', 'merchantId':7}));
// //     if (mounted) {
// //       if (response.statusCode == 200) {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Category "$name" added.', isSuccess: true);
// //         _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to add category.', isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _deleteCategory(FoodCategory category) async {
// //     final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Category?'), content: Text('Are you sure you want to delete "${category.name}"?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
// //     if (confirm != true) return;
// //     final token = await _storage.read(key: 'jwt_token');
// //     final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.foodCategories}/${category.id}'), headers: {'Authorization': 'Bearer $token'});
// //     if (mounted) {
// //       if (response.statusCode == 204 || response.statusCode == 200) {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: 'Category "${category.name}" deleted.', isSuccess: true);
// //         _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete category. It may still contain menu items.', isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   void _showAddCategoryDialog() {
// //     final nameController = TextEditingController();
// //     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add New Category'), content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () {if (nameController.text.isNotEmpty) {Navigator.pop(context); _addCategory(nameController.text);}}, child: const Text('Add'))]));
// //   }
// //
// //   void _showManageCategoriesDialog() {
// //     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Manage Categories'), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: _categories.length, itemBuilder: (context, index) {final category = _categories[index]; return ListTile(title: Text(category.name), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {Navigator.pop(context); _deleteCategory(category);}));})), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
// //   }
// //
// //   Future<void> _showFoodDialog({MenuItem? item}) async {
// //     final formKey = GlobalKey<FormState>();
// //     final nameController = TextEditingController(text: item?.name ?? '');
// //     final priceController = TextEditingController(text: item?.price.toString() ?? '');
// //     final costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '');
// //     final stockController = TextEditingController(text: item?.stock.toString() ?? '');
// //     XFile? pickedImage;
// //     int selectedCategoryId = item?.categoryId ?? (_tabController != null ? _categories[_tabController!.index].id : 0);
// //
// //     await showDialog(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setStateDialog) => AlertDialog(title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'), content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [GestureDetector(onTap: () async {final picker = ImagePicker(); final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); if (file != null) setStateDialog(() => pickedImage = file);}, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)), child: ClipRRect(borderRadius: BorderRadius.circular(11),
// //         // FIXED: This block now handles the null 'pickedImage' safely.
// //         child: Builder(
// //           builder: (context) {
// //             final localPickedImage = pickedImage; // Create a local, non-nullable variable.
// //             if (localPickedImage != null) {
// //               return kIsWeb ? Image.network(localPickedImage.path, fit: BoxFit.cover) : Image.file(File(localPickedImage.path), fit: BoxFit.cover);
// //             } else if (item?.imagePath.isNotEmpty ?? false) {
// //               return Image.network(ApiConstants.baseUrl + ApiConstants.uploads + item!.imagePath, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.camera_alt, color: Colors.grey, size: 40));
// //             } else {
// //               return const Icon(Icons.camera_alt, color: Colors.grey, size: 40);
// //             }
// //           },
// //         )
// //     ))), const SizedBox(height: 16), TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null), const SizedBox(height: 12), TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null), const SizedBox(height: 12), TextFormField(controller: costPriceController, decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null), const SizedBox(height: 12), TextFormField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () {if (!formKey.currentState!.validate()) return; Navigator.pop(context); _saveMenuItem(item: item, name: nameController.text, price: double.parse(priceController.text), costPrice: double.parse(costPriceController.text), stock: int.parse(stockController.text), categoryId: selectedCategoryId, image: pickedImage);}, child: const Text('Save'))])));
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Manage Menu'), actions: [PopupMenuButton<String>(onSelected: (value) {if (value == 'add_category') _showAddCategoryDialog(); if (value == 'manage_categories') _showManageCategoriesDialog();}, itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[const PopupMenuItem<String>(value: 'add_category', child: Text('Add New Category')), const PopupMenuItem<String>(value: 'manage_categories', child: Text('Manage Categories'))])], bottom: _isLoading ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator()) : (_categories.isEmpty ? null : TabBar(controller: _tabController, isScrollable: true, tabs: _categories.map((c) => Tab(text: c.name)).toList()))),
// //       body: _isLoading ? _buildShimmer() : (_categories.isEmpty ? const Center(child: Text("No categories found.\nAdd a category to begin.", textAlign: TextAlign.center)) : TabBarView(controller: _tabController, children: _categories.map((category) => _buildMenuList(category)).toList())),
// //       floatingActionButton: _categories.isEmpty ? null : FloatingActionButton.extended(onPressed: () => _showFoodDialog(), label: const Text('Add Item'), icon: const Icon(Icons.add)),
// //     );
// //   }
// //
// //   Widget _buildMenuList(FoodCategory category) {
// //     final items = _foodItems.where((item) => item.categoryId == category.id).toList();
// //     if (items.isEmpty) return const Center(child: Text("No items in this category yet."));
// //     return AnimationLimiter(
// //       child: ListView.builder(
// //         padding: const EdgeInsets.only(bottom: 80, top: 8),
// //         itemCount: items.length,
// //         itemBuilder: (context, index) {
// //           final item = items[index];
// //           return AnimationConfiguration.staggeredList(
// //             position: index,
// //             duration: const Duration(milliseconds: 375),
// //             child: SlideAnimation(
// //               verticalOffset: 50.0,
// //               child: FadeInAnimation(
// //                 child: Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ApiConstants.baseUrl + ApiConstants.uploads + item.imagePath, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 30))), title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Price: Rs. ${item.price.toStringAsFixed(2)} | Stock: ${item.stock}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showFoodDialog(item: item)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMenuItem(item))]))),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _buildShimmer() {
// //     return Shimmer.fromColors(
// //       baseColor: Colors.grey[300]!,
// //       highlightColor: Colors.grey[100]!,
// //       child: ListView(children: [Container(height: 50, color: Colors.white, margin: const EdgeInsets.all(8)), ...List.generate(5, (index) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.white), title: Container(height: 10, color: Colors.white), subtitle: Container(height: 10, color: Colors.white, width: 50))))]),
// //     );
// //   }
// // }
//
// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/foundation.dart' show kIsWeb;
// // import 'package:flutter/material.dart';
// // import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// // import 'package:food_app/api/api_constants.dart';
// // import 'package:food_app/models/food_category.dart';
// // import 'package:food_app/models/menu_item.dart';
// // import 'package:food_app/utils/notification_utils.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:image_picker/image_picker.dart';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // import 'package:shimmer/shimmer.dart';
// //
// // class ManageMenuScreen extends StatefulWidget {
// //   const ManageMenuScreen({super.key});
// //
// //   @override
// //   State<ManageMenuScreen> createState() => _ManageMenuScreenState();
// // }
// //
// // class _ManageMenuScreenState extends State<ManageMenuScreen> with SingleTickerProviderStateMixin {
// //   final _storage = const FlutterSecureStorage();
// //   List<FoodCategory> _categories = [];
// //   List<MenuItem> _foodItems = [];
// //   bool _isLoading = true;
// //   String? _errorMessage;
// //   TabController? _tabController;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadData();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _tabController?.dispose();
// //     super.dispose();
// //   }
// //
// //   // --- DATA LOADING & API METHODS ---
// //
// //   Future<void> _loadData() async {
// //     setState(() { _isLoading = true; _errorMessage = null; });
// //     try {
// //       // Run API calls in parallel for faster loading
// //       await Future.wait([_loadCategories(), _loadFoodItems()]);
// //     } catch (e) {
// //       if (mounted) setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
// //     } finally {
// //       _updateTabController();
// //       if (mounted) setState(() => _isLoading = false);
// //     }
// //   }
// //
// //   Future<void> _loadCategories() async {
// //     final token = await _storage.read(key: 'jwt_token');
// //     final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Authorization': 'Bearer $token'});
// //     if (response.statusCode == 200) {
// //       final List data = jsonDecode(response.body);
// //       if (mounted) _categories = data.map((json) => FoodCategory.fromJson(json)).toList();
// //     } else {
// //       throw Exception('Failed to load categories.');
// //     }
// //   }
// //
// //   Future<void> _loadFoodItems() async {
// //     final token = await _storage.read(key: 'jwt_token');
// //
// //     // FIX: Change this line to call the correct endpoint
// //     final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.merchantMenu);
// //
// //     final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
// //
// //     if (response.statusCode == 200) {
// //       final List data = jsonDecode(response.body);
// //       if (mounted) {
// //         setState(() {
// //           _foodItems = data.map((json) => MenuItem.fromJson(json)).toList();
// //         });
// //       }
// //     } else {
// //       throw Exception('Failed to load menu items.');
// //     }
// //   }
// //
// //   void _updateTabController() {
// //     if (!mounted) return;
// //     if (_categories.isEmpty) {
// //       if (_tabController != null) {
// //         _tabController?.dispose();
// //         _tabController = null;
// //       }
// //     } else {
// //       final oldIndex = _tabController?.index ?? 0;
// //       _tabController?.dispose();
// //       _tabController = TabController(length: _categories.length, vsync: this, initialIndex: oldIndex < _categories.length ? oldIndex : 0);
// //     }
// //     setState(() {});
// //   }
// //
// //   Future<String?> _uploadImage(XFile imageFile) async {
// //     final token = await _storage.read(key: 'jwt_token');
// //     final url = Uri.parse('${ApiConstants.baseUrl}/api/uploads');
// //     final request = http.MultipartRequest('POST', url)..headers['Authorization'] = 'Bearer $token';
// //
// //     request.files.add(kIsWeb
// //         ? http.MultipartFile.fromBytes('file', await imageFile.readAsBytes(), filename: imageFile.name)
// //         : await http.MultipartFile.fromPath('file', imageFile.path));
// //
// //     final response = await request.send();
// //     if (response.statusCode == 200) {
// //       return await response.stream.bytesToString();
// //     }
// //     return null;
// //   }
// //
// //   Future<void> _saveMenuItem({MenuItem? item, required String name, required double price, required double costPrice, required int stock, required int categoryId, XFile? image}) async {
// //     String? imagePath = item?.imagePath;
// //     if (image != null) {
// //       imagePath = await _uploadImage(image);
// //       if (imagePath == null) {
// //         if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Image upload failed.", isSuccess: false);
// //         return;
// //       }
// //     }
// //     if (imagePath == null && item == null) {
// //       if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: "An image is required for new items.", isSuccess: false);
// //       return;
// //     }
// //
// //     final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.merchantMenu);
// //     final token = await _storage.read(key: 'jwt_token');
// //     final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
// //     final body = json.encode({'id': item?.id, 'name': name, 'price': price, 'costPrice': costPrice, 'stock': stock, 'categoryId': categoryId, 'imagePath': imagePath});
// //
// //     final response = item == null ? await http.post(url, headers: headers, body: body) : await http.put(url, headers: headers, body: body);
// //
// //     if (mounted) {
// //       if (response.statusCode == 200 || response.statusCode == 201) {
// //         NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Menu item has been saved.", isSuccess: true);
// //         _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Failed to save item: ${response.body}", isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _addCategory(String name) async {
// //     final token = await _storage.read(key: 'jwt_token');
// //     final body = json.encode({'name': name, 'description': 'New category'});
// //     final response = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: body);
// //     if (mounted) {
// //       if (response.statusCode == 201) {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Category "$name" added.', isSuccess: true);
// //         await _loadData();
// //       } else {
// //         final error = jsonDecode(response.body)['message'] ?? 'Failed to add category.';
// //         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: error, isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _deleteMenuItem(MenuItem item) async {
// //     final bool? confirm = await _showConfirmDialog('Delete Item?', 'Are you sure you want to delete "${item.name}"?');
// //     if (confirm != true) return;
// //
// //     final token = await _storage.read(key: 'jwt_token');
// //     final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.merchantMenu}/${item.id}');
// //     final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
// //
// //     if (mounted) {
// //       if (response.statusCode == 204) {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: '${item.name} has been deleted.', isSuccess: true);
// //         _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete item. It might be in use.', isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _deleteCategory(FoodCategory category) async {
// //     final bool? confirm = await _showConfirmDialog('Delete Category?', 'Are you sure you want to delete "${category.name}"? This cannot be undone.');
// //     if (confirm != true) return;
// //
// //     final token = await _storage.read(key: 'jwt_token');
// //     final url = Uri.parse('${ApiConstants.baseUrl}/api/food-categories/${category.id}');
// //     final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
// //
// //     if (mounted) {
// //       if (response.statusCode == 204) {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: 'Category "${category.name}" deleted.', isSuccess: true);
// //         await _loadData();
// //       } else {
// //         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete category. It may still contain items.', isSuccess: false);
// //       }
// //     }
// //   }
// //
// //   // --- DIALOGS & UI METHODS ---
// //
// //   Future<bool?> _showConfirmDialog(String title, String content) {
// //     return showDialog<bool>(
// //         context: context,
// //         builder: (context) => AlertDialog(
// //           title: Text(title),
// //           content: Text(content),
// //           actions: [
// //             TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
// //             TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))
// //           ],
// //         )
// //     );
// //   }
// //
// //   void _showAddCategoryDialog() {
// //     final nameController = TextEditingController();
// //     showDialog(
// //         context: context,
// //         builder: (context) => AlertDialog(
// //             title: const Text('Add New Category'),
// //             content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name'), autofocus: true),
// //             actions: [
// //               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
// //               ElevatedButton(onPressed: () {
// //                 if (nameController.text.isNotEmpty) {
// //                   Navigator.pop(context);
// //                   _addCategory(nameController.text);
// //                 }
// //               }, child: const Text('Add'))
// //             ]
// //         )
// //     );
// //   }
// //
// //   void _showManageCategoriesDialog() {
// //     showDialog(
// //         context: context,
// //         builder: (context) => AlertDialog(
// //             title: const Text('Manage Categories'),
// //             content: SizedBox(
// //                 width: double.maxFinite,
// //                 child: ListView.builder(
// //                     shrinkWrap: true,
// //                     itemCount: _categories.length,
// //                     itemBuilder: (context, index) {
// //                       final category = _categories[index];
// //                       return ListTile(
// //                           title: Text(category.name),
// //                           trailing: IconButton(
// //                               icon: const Icon(Icons.delete_outline, color: Colors.red),
// //                               onPressed: () {
// //                                 Navigator.pop(context);
// //                                 _deleteCategory(category);
// //                               }
// //                           )
// //                       );
// //                     }
// //                 )
// //             ),
// //             actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]
// //         )
// //     );
// //   }
// //
// //   Future<void> _showFoodDialog({MenuItem? item}) async {
// //     final formKey = GlobalKey<FormState>();
// //     final nameController = TextEditingController(text: item?.name ?? '');
// //     final priceController = TextEditingController(text: item?.price.toString() ?? '');
// //     final costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '');
// //     final stockController = TextEditingController(text: item?.stock.toString() ?? '');
// //     XFile? pickedImage;
// //     int? selectedCategoryId = item?.categoryId;
// //
// //     if (selectedCategoryId == null && _categories.isNotEmpty && _tabController != null) {
// //       selectedCategoryId = _categories[_tabController!.index].id;
// //     }
// //
// //     await showDialog(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (context) => StatefulBuilder(
// //             builder: (context, setStateDialog) => AlertDialog(
// //               title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'),
// //               content: Form(
// //                 key: formKey,
// //                 child: SingleChildScrollView(
// //                     child: Column(mainAxisSize: MainAxisSize.min, children: [
// //                       GestureDetector(
// //                           onTap: () async {
// //                             final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
// //                             if (file != null) setStateDialog(() => pickedImage = file);
// //                           },
// //                           child: Container(
// //                               width: 120, height: 120,
// //                               decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
// //                               child: ClipRRect(
// //                                 borderRadius: BorderRadius.circular(11),
// //                                 child: Builder(
// //                                   builder: (context) {
// //                                     if (pickedImage != null) {
// //                                       return kIsWeb ? Image.network(pickedImage!.path, fit: BoxFit.cover) : Image.file(File(pickedImage!.path), fit: BoxFit.cover);
// //                                     } else if (item?.imagePath.isNotEmpty ?? false) {
// //                                       return Image.network('${ApiConstants.baseUrl}${ApiConstants.uploads}${item!.imagePath}', fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.camera_alt, color: Colors.grey, size: 40));
// //                                     } else {
// //                                       return const Icon(Icons.camera_alt, color: Colors.grey, size: 40);
// //                                     }
// //                                   },
// //                                 ),
// //                               )
// //                           )
// //                       ),
// //                       const SizedBox(height: 16),
// //                       if (_categories.isNotEmpty)
// //                         DropdownButtonFormField<int>(
// //                           value: selectedCategoryId,
// //                           items: _categories.map((cat) => DropdownMenuItem<int>(value: cat.id, child: Text(cat.name))).toList(),
// //                           onChanged: (val) => setStateDialog(() => selectedCategoryId = val),
// //                           decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
// //                           validator: (v) => v == null ? 'Required' : null,
// //                         ),
// //                       const SizedBox(height: 12),
// //                       TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
// //                       const SizedBox(height: 12),
// //                       TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
// //                       const SizedBox(height: 12),
// //                       TextFormField(controller: costPriceController, decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
// //                       const SizedBox(height: 12),
// //                       TextFormField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)
// //                     ])
// //                 ),
// //               ),
// //               actions: [
// //                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
// //                 ElevatedButton(
// //                     onPressed: () {
// //                       if (!formKey.currentState!.validate() || selectedCategoryId == null) return;
// //                       Navigator.pop(context);
// //                       _saveMenuItem(item: item, name: nameController.text, price: double.parse(priceController.text), costPrice: double.parse(costPriceController.text), stock: int.parse(stockController.text), categoryId: selectedCategoryId!, image: pickedImage);
// //                     },
// //                     child: const Text('Save'))
// //               ],
// //             )
// //         )
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Manage Menu'),
// //         actions: [
// //           if (!_isLoading && _categories.isNotEmpty)
// //             PopupMenuButton<String>(
// //               onSelected: (value) {
// //                 if (value == 'add_category') _showAddCategoryDialog();
// //                 if (value == 'manage_categories') _showManageCategoriesDialog();
// //               },
// //               itemBuilder: (context) => [
// //                 const PopupMenuItem(value: 'add_category', child: Text('Add New Category')),
// //                 const PopupMenuItem(value: 'manage_categories', child: Text('Manage Categories')),
// //               ],
// //             )
// //         ],
// //         bottom: _isLoading
// //             ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator())
// //             : (_tabController == null ? null : TabBar(controller: _tabController, isScrollable: true, tabs: _categories.map((c) => Tab(text: c.name)).toList())),
// //       ),
// //       body: _buildBody(),
// //       floatingActionButton: _isLoading || _categories.isEmpty ? null : FloatingActionButton.extended(onPressed: () => _showFoodDialog(), label: const Text('Add Item'), icon: const Icon(Icons.add)),
// //     );
// //   }
// //
// //   Widget _buildBody() {
// //     if (_isLoading) return _buildShimmer();
// //     if (_errorMessage != null) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: $_errorMessage\nPlease pull down to refresh.', textAlign: TextAlign.center)));
// //     if (_categories.isEmpty || _tabController == null) {
// //       return Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               const Text("No categories found.\nAdd a category to begin.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
// //               const SizedBox(height: 16),
// //               ElevatedButton.icon(onPressed: _showAddCategoryDialog, icon: const Icon(Icons.add), label: const Text("Add Category")),
// //             ],
// //           )
// //       );
// //     }
// //
// //     return TabBarView(
// //       controller: _tabController,
// //       children: _categories.map((category) => _buildMenuList(category)).toList(),
// //     );
// //   }
// //
// //   Widget _buildMenuList(FoodCategory category) {
// //     final items = _foodItems.where((item) => item.categoryId == category.id).toList();
// //     if (items.isEmpty) return const Center(child: Text("No items in this category yet. Tap the '+' button to add one."));
// //
// //     return AnimationLimiter(
// //       child: RefreshIndicator(
// //         onRefresh: _loadData,
// //         child: ListView.builder(
// //           padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
// //           itemCount: items.length,
// //           itemBuilder: (context, index) {
// //             final item = items[index];
// //             return AnimationConfiguration.staggeredList(
// //               position: index,
// //               duration: const Duration(milliseconds: 375),
// //               child: SlideAnimation(
// //                 verticalOffset: 50.0,
// //                 child: FadeInAnimation(
// //                   child: Card(
// //                       elevation: 2,
// //                       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //                       child: ListTile(
// //                           leading: ClipRRect(
// //                             borderRadius: BorderRadius.circular(8),
// //                             child: Image.network(
// //                                 '${ApiConstants.baseUrl}${ApiConstants.uploads}${item.imagePath}',
// //                                 width: 56, height: 56, fit: BoxFit.cover,
// //                                 errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 30)
// //                             ),
// //                           ),
// //                           title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
// //                           subtitle: Text("Price: Rs. ${item.price.toStringAsFixed(2)} | Stock: ${item.stock}"),
// //                           trailing: Row(mainAxisSize: MainAxisSize.min, children: [
// //                             IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showFoodDialog(item: item)),
// //                             IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMenuItem(item))
// //                           ])
// //                       )
// //                   ),
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildShimmer() {
// //     return Shimmer.fromColors(
// //         baseColor: Colors.grey[300]!,
// //         highlightColor: Colors.grey[100]!,
// //         child: ListView.builder(
// //           itemCount: 8,
// //           itemBuilder: (_, __) => Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //             child: Row(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: <Widget>[
// //                 Container(width: 56.0, height: 56.0, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
// //                 const SizedBox(width: 16),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: <Widget>[
// //                       Container(width: double.infinity, height: 10.0, color: Colors.white),
// //                       const SizedBox(height: 6),
// //                       Container(width: 100, height: 10.0, color: Colors.white),
// //                     ],
// //                   ),
// //                 )
// //               ],
// //             ),
// //           ),
// //         )
// //     );
// //   }
// // }
//
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/food_category.dart';
// import 'package:food_app/models/menu_item.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:food_app/widgets/image_from_base64.dart'; // FIX: Import the image decoder widget
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:shimmer/shimmer.dart';
//
// class ManageMenuScreen extends StatefulWidget {
//   const ManageMenuScreen({super.key});
//
//   @override
//   State<ManageMenuScreen> createState() => _ManageMenuScreenState();
// }
//
// class _ManageMenuScreenState extends State<ManageMenuScreen>
//     with SingleTickerProviderStateMixin {
//   final _storage = const FlutterSecureStorage();
//   List<FoodCategory> _categories = [];
//   List<MenuItem> _foodItems = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   TabController? _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   @override
//   void dispose() {
//     _tabController?.dispose();
//     super.dispose();
//   }
//
//   // --- DATA LOADING & API METHODS ---
//
//   Future<void> _loadData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//     try {
//       await Future.wait([_loadCategories(), _loadFoodItems()]);
//     } catch (e) {
//       if (mounted) {
//         setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
//       }
//     } finally {
//       _updateTabController();
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _loadCategories() async {
//     final token = await _storage.read(key: 'jwt_token');
//     final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
//         headers: {'Authorization': 'Bearer $token'});
//     if (response.statusCode == 200) {
//       final List data = jsonDecode(response.body);
//       if (mounted) {
//         _categories = data.map((json) => FoodCategory.fromJson(json)).toList();
//       }
//     } else {
//       throw Exception('Failed to load categories.');
//     }
//   }
//
//   Future<void> _loadFoodItems() async {
//     final token = await _storage.read(key: 'jwt_token');
//     // FIX: This endpoint should fetch from the general menu-items endpoint, not a merchant-specific one, for consistency.
//     final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems);
//     final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
//
//     if (response.statusCode == 200) {
//       final List data = jsonDecode(response.body);
//       if (mounted) {
//         setState(() {
//           _foodItems = data.map((json) => MenuItem.fromJson(json)).toList();
//         });
//       }
//     } else {
//       throw Exception('Failed to load menu items.');
//     }
//   }
//
//   void _updateTabController() {
//     if (!mounted) return;
//     if (_categories.isEmpty) {
//       _tabController?.dispose();
//       _tabController = null;
//     } else {
//       final oldIndex = _tabController?.index ?? 0;
//       _tabController?.dispose();
//       _tabController = TabController(
//           length: _categories.length,
//           vsync: this,
//           initialIndex: oldIndex < _categories.length ? oldIndex : 0);
//     }
//     setState(() {});
//   }
//
//   // FIX: This entire function is rewritten to follow the new API logic.
//   // The logic is now: 1. Save item data. 2. If there's an image, upload it to the new item's ID.
//   Future<void> _saveMenuItem(
//       {MenuItem? item,
//         required String name,
//         required double price,
//         required double costPrice,
//         required int stock,
//         required int categoryId,
//         XFile? image}) async {
//     final token = await _storage.read(key: 'jwt_token');
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token'
//     };
//
//     // Step 1: Create or Update the menu item TEXT data first.
//     final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems);
//     final body = json.encode({
//       'id': item?.id,
//       'name': name,
//       'price': price,
//       'costPrice': costPrice,
//       'stock': stock,
//       'categoryId': categoryId,
//     });
//
//     try {
//       // Use PUT for update, POST for create
//       final response = item == null
//           ? await http.post(url, headers: headers, body: body)
//           : await http.put(url, headers: headers, body: body);
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final savedItemData = jsonDecode(response.body);
//         final int savedItemId = savedItemData['id'];
//
//         // Step 2: If there's a new image, upload it to the item's specific image endpoint.
//         if (image != null) {
//           final imageUploadUrl = Uri.parse('${ApiConstants.baseUrl}/api/menu-items/$savedItemId/image');
//           final request = http.MultipartRequest('POST', imageUploadUrl)
//             ..headers['Authorization'] = 'Bearer $token';
//
//           request.files.add(kIsWeb
//               ? http.MultipartFile.fromBytes('file', await image.readAsBytes(), filename: image.name)
//               : await http.MultipartFile.fromPath('file', image.path));
//
//           final imageResponse = await request.send();
//           if (imageResponse.statusCode != 200) {
//             throw Exception('Item data saved, but image upload failed.');
//           }
//         }
//
//         if (mounted) {
//           NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Menu item has been saved.", isSuccess: true);
//           _loadData(); // Reload all data to show changes
//         }
//       } else {
//         throw Exception('Failed to save item: ${response.body}');
//       }
//     } catch (e) {
//       if (mounted) {
//         NotificationUtils.showAnimatedPopup(context, title: "Error", message: e.toString(), isSuccess: false);
//       }
//     }
//   }
//
//
//   Future<void> _addCategory(String name) async {
//     final token = await _storage.read(key: 'jwt_token');
//     final body = json.encode({'name': name, 'description': 'New category'});
//     final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
//         headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
//         body: body);
//     if (mounted) {
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         NotificationUtils.showAnimatedPopup(context,
//             title: 'Success', message: 'Category "$name" added.', isSuccess: true);
//         await _loadData();
//       } else {
//         final error = jsonDecode(response.body)['message'] ?? 'Failed to add category.';
//         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: error, isSuccess: false);
//       }
//     }
//   }
//
//   Future<void> _deleteMenuItem(MenuItem item) async {
//     final bool? confirm = await _showConfirmDialog(
//         'Delete Item?', 'Are you sure you want to delete "${item.name}"?');
//     if (confirm != true) return;
//
//     final token = await _storage.read(key: 'jwt_token');
//     // FIX: Use the correct general endpoint for menu items
//     final url = Uri.parse('${ApiConstants.baseUrl}/api/menu-items/${item.id}');
//     final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
//
//     if (mounted) {
//       if (response.statusCode == 204 || response.statusCode == 200) {
//         NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: '${item.name} has been deleted.', isSuccess: true);
//         _loadData();
//       } else {
//         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete item. It might be in use.', isSuccess: false);
//       }
//     }
//   }
//
//   // --- DIALOGS & UI METHODS ---
//
//   Future<void> _showFoodDialog({MenuItem? item}) async {
//     final formKey = GlobalKey<FormState>();
//     final nameController = TextEditingController(text: item?.name ?? '');
//     final priceController = TextEditingController(text: item?.price.toString() ?? '');
//     final costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '');
//     final stockController = TextEditingController(text: item?.stock.toString() ?? '');
//     XFile? pickedImage;
//     int? selectedCategoryId = item?.categoryId;
//
//     if (selectedCategoryId == null && _categories.isNotEmpty && _tabController != null) {
//       selectedCategoryId = _categories[_tabController!.index].id;
//     }
//
//     await showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => StatefulBuilder(
//             builder: (context, setStateDialog) => AlertDialog(
//               title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'),
//               content: Form(
//                 key: formKey,
//                 child: SingleChildScrollView(
//                     child: Column(mainAxisSize: MainAxisSize.min, children: [
//                       GestureDetector(
//                           onTap: () async {
//                             final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
//                             if (file != null) {
//                               setStateDialog(() => pickedImage = file);
//                             }
//                           },
//                           child: Container(
//                               width: 120, height: 120,
//                               decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(11),
//                                 child: Builder(
//                                   builder: (context) {
//                                     if (pickedImage != null) {
//                                       return kIsWeb ? Image.network(pickedImage!.path, fit: BoxFit.cover) : Image.file(File(pickedImage!.path), fit: BoxFit.cover);
//                                     }
//                                     // FIX: Use ImageFromBase64 and access 'item.image'
//                                     return ImageFromBase64(base64String: item?.image, placeholder: const Icon(Icons.camera_alt, color: Colors.grey, size: 40));
//                                   },
//                                 ),
//                               ))),
//                       const SizedBox(height: 16),
//                       if (_categories.isNotEmpty)
//                         DropdownButtonFormField<int>(
//                           value: selectedCategoryId,
//                           items: _categories.map((cat) => DropdownMenuItem<int>(value: cat.id, child: Text(cat.name))).toList(),
//                           onChanged: (val) => setStateDialog(() => selectedCategoryId = val),
//                           decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
//                           validator: (v) => v == null ? 'Required' : null,
//                         ),
//                       const SizedBox(height: 12),
//                       TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
//                       const SizedBox(height: 12),
//                       TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
//                       const SizedBox(height: 12),
//                       TextFormField(controller: costPriceController, decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
//                       const SizedBox(height: 12),
//                       TextFormField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)
//                     ])),
//               ),
//               actions: [
//                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                 ElevatedButton(
//                     onPressed: () {
//                       if (!formKey.currentState!.validate() || selectedCategoryId == null) return;
//                       Navigator.pop(context);
//                       _saveMenuItem(
//                           item: item,
//                           name: nameController.text,
//                           price: double.parse(priceController.text),
//                           costPrice: double.parse(costPriceController.text),
//                           stock: int.parse(stockController.text),
//                           categoryId: selectedCategoryId!,
//                           image: pickedImage);
//                     },
//                     child: const Text('Save'))
//               ],
//             )));
//   }
//
//   // --- BUILD METHODS ---
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Menu'),
//         bottom: _isLoading
//             ? const PreferredSize(
//             preferredSize: Size.fromHeight(4.0),
//             child: LinearProgressIndicator())
//             : (_tabController == null
//             ? null
//             : TabBar(
//             controller: _tabController,
//             isScrollable: true,
//             tabs: _categories.map((c) => Tab(text: c.name)).toList())),
//       ),
//       body: _buildBody(),
//       floatingActionButton: _isLoading || _categories.isEmpty
//           ? null
//           : FloatingActionButton.extended(
//           onPressed: () => _showFoodDialog(),
//           label: const Text('Add Item'),
//           icon: const Icon(Icons.add)),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) return _buildShimmer();
//     if (_errorMessage != null) {
//       return Center(
//           child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text('Error: $_errorMessage\nPlease pull down to refresh.',
//                   textAlign: TextAlign.center)));
//     }
//     if (_categories.isEmpty || _tabController == null) {
//       return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text("No categories found.\nAdd a category to begin.",
//                   textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
//               const SizedBox(height: 16),
//               ElevatedButton.icon(
//                   onPressed: _showAddCategoryDialog,
//                   icon: const Icon(Icons.add),
//                   label: const Text("Add Category")),
//             ],
//           ));
//     }
//
//     return TabBarView(
//       controller: _tabController,
//       children: _categories.map((category) => _buildMenuList(category)).toList(),
//     );
//   }
//
//   Widget _buildMenuList(FoodCategory category) {
//     final items = _foodItems.where((item) => item.categoryId == category.id).toList();
//     if (items.isEmpty) {
//       return const Center(
//           child: Text(
//               "No items in this category yet.\nTap the '+' button to add one.",
//               textAlign: TextAlign.center));
//     }
//
//     return AnimationLimiter(
//       child: RefreshIndicator(
//         onRefresh: _loadData,
//         child: ListView.builder(
//           padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
//           itemCount: items.length,
//           itemBuilder: (context, index) {
//             final item = items[index];
//             return AnimationConfiguration.staggeredList(
//               position: index,
//               duration: const Duration(milliseconds: 375),
//               child: SlideAnimation(
//                 verticalOffset: 50.0,
//                 child: FadeInAnimation(
//                   child: Card(
//                       elevation: 2,
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 6),
//                       child: ListTile(
//                           leading: ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             // FIX: Use ImageFromBase64 and access 'item.image'
//                             child: SizedBox(
//                               width: 56,
//                               height: 56,
//                               child: ImageFromBase64(
//                                 base64String: item.image,
//                                 placeholder: const Icon(Icons.fastfood, size: 30),
//                               ),
//                             ),
//                           ),
//                           title: Text(item.name,
//                               style:
//                               const TextStyle(fontWeight: FontWeight.bold)),
//                           subtitle: Text(
//                               "Price: Rs. ${item.price.toStringAsFixed(2)} | Stock: ${item.stock}"),
//                           trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                     icon: const Icon(Icons.edit_outlined,
//                                         color: Colors.blueGrey),
//                                     onPressed: () => _showFoodDialog(item: item)),
//                                 IconButton(
//                                     icon: const Icon(Icons.delete_outline,
//                                         color: Colors.red),
//                                     onPressed: () => _deleteMenuItem(item))
//                               ]))),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   // --- Other helper methods like _showConfirmDialog, _showAddCategoryDialog, _buildShimmer etc. can remain as they are ---
//   Future<bool?> _showConfirmDialog(String title, String content) =>
//       showDialog<bool>(context: context, builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(content),
//         actions: [
//           TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))
//         ],
//       ));
//
//   void _showAddCategoryDialog() {
//     final nameController = TextEditingController();
//     showDialog(context: context, builder: (context) => AlertDialog(
//         title: const Text('Add New Category'),
//         content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name'), autofocus: true),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           ElevatedButton(onPressed: () {
//             if (nameController.text.isNotEmpty) {
//               Navigator.pop(context);
//               _addCategory(nameController.text);
//             }
//           }, child: const Text('Add'))
//         ]));
//   }
//
//   Widget _buildShimmer() {
//     return Shimmer.fromColors(
//         baseColor: Colors.grey[300]!,
//         highlightColor: Colors.grey[100]!,
//         child: ListView.builder(
//           itemCount: 8,
//           itemBuilder: (_, __) => Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: <Widget>[
//                 Container(width: 56.0, height: 56.0, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       Container(width: double.infinity, height: 10.0, color: Colors.white),
//                       const SizedBox(height: 6),
//                       Container(width: 100, height: 10.0, color: Colors.white),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ));
//   }
// }




import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/food_category.dart';
import 'package:food_app/models/menu_item.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/custom_cached_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final _storage = const FlutterSecureStorage();
  List<FoodCategory> _categories = [];
  List<MenuItem> _foodItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _loadCategories();
      if (_categories.isNotEmpty) {
        await _loadFoodItems();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
        headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _categories = data.map((json) => FoodCategory.fromJson(json)).toList();
        });
      }
    } else {
      throw Exception('Failed to load categories.');
    }
  }

  Future<void> _loadFoodItems() async {
    final token = await _storage.read(key: 'jwt_token');
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems);
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _foodItems = data.map((json) => MenuItem.fromJson(json)).toList();
        });
      }
    } else {
      throw Exception('Failed to load menu items.');
    }
  }

  Future<void> _saveMenuItem(
      {MenuItem? item,
        required String name,
        required double price,
        required double costPrice,
        required int stock,
        required int categoryId,
        XFile? image}) async {
    final token = await _storage.read(key: 'jwt_token');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    final isCreating = item == null;
    final url = isCreating
        ? Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems)
        : Uri.parse('${ApiConstants.baseUrl}/api/menu-items/${item.id}');
    final body = json.encode({'name': name, 'price': price, 'costPrice': costPrice, 'stock': stock, 'categoryId': categoryId});

    try {
      final response = isCreating
          ? await http.post(url, headers: headers, body: body)
          : await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final savedItemData = jsonDecode(response.body);
        final int savedItemId = savedItemData['id'];
        if (image != null) {
          final imageUploadUrl = Uri.parse('${ApiConstants.baseUrl}/api/menu-items/$savedItemId/image');
          final request = http.MultipartRequest('POST', imageUploadUrl)..headers['Authorization'] = 'Bearer $token';
          request.files.add(kIsWeb
              ? http.MultipartFile.fromBytes('file', await image.readAsBytes(), filename: image.name)
              : await http.MultipartFile.fromPath('file', image.path));
          final imageResponse = await request.send();
          if (imageResponse.statusCode != 200) throw Exception('Item data saved, but image upload failed.');
        }
        if (mounted) {
          NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Menu item has been saved.", isSuccess: true);
          await _loadFoodItems();
        }
      } else {
        throw Exception('Failed to save item: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: e.toString(), isSuccess: false);
    }
  }

  Future<void> _addCategory(String name) async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    final body = json.encode({'name': name, 'description': 'New category'});
    final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: body);
    if (mounted) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Category "$name" added.', isSuccess: true);
        await _loadCategories();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to add category.';
        NotificationUtils.showAnimatedPopup(context, title: 'Error', message: error, isSuccess: false);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(FoodCategory category) async {
    final bool? confirm = await _showConfirmDialog('Delete Category?', 'Are you sure you want to delete "${category.name}"?');
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    final url = Uri.parse('${ApiConstants.baseUrl}/api/food-categories/${category.id}');
    final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

    if (mounted) {
      if (response.statusCode == 204 || response.statusCode == 200) {
        NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: 'Category "${category.name}" deleted.', isSuccess: true);
        await _loadCategories();
        setState(() {
          _foodItems.removeWhere((item) => item.categoryId == category.id);
        });
      } else {
        NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete. Category may contain items.', isSuccess: false);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final bool? confirm = await _showConfirmDialog('Delete Item?', 'Are you sure you want to delete "${item.name}"?');
    if (confirm != true) return;

    final token = await _storage.read(key: 'jwt_token');
    final url = Uri.parse('${ApiConstants.baseUrl}/api/menu-items/${item.id}');
    final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

    if (mounted) {
      if (response.statusCode == 204 || response.statusCode == 200) {
        NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: '${item.name} has been deleted.', isSuccess: true);
        setState(() {
          _foodItems.removeWhere((menuItem) => menuItem.id == item.id);
        });
      } else {
        NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete item. It might be in use.', isSuccess: false);
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (nameController.text.isNotEmpty) {
              Navigator.pop(context);
              _addCategory(nameController.text);
            }
          }, child: const Text('Add'))
        ]));
  }

  void _showManageCategoriesDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Manage Categories'),
            content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ListTile(
                          title: Text(category.name),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteCategory(category);
                              }));
                    })),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  Future<void> _showFoodDialog({MenuItem? item, required BuildContext context}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '');
    final stockController = TextEditingController(text: item?.stock.toString() ?? '');
    XFile? pickedImage;
    int? selectedCategoryId = item?.categoryId;

    if (selectedCategoryId == null && _categories.isNotEmpty) {
      final currentTabIndex = DefaultTabController.of(context).index;
      if (currentTabIndex < _categories.length) {
        selectedCategoryId = _categories[currentTabIndex].id;
      }
    }

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
              title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                          onTap: () async {
                            final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                            if (file != null) setStateDialog(() => pickedImage = file);
                          },
                          child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Builder(builder: (context) {
                                  if (pickedImage != null) {
                                    return kIsWeb ? Image.network(pickedImage!.path, fit: BoxFit.cover) : Image.file(File(pickedImage!.path), fit: BoxFit.cover);
                                  }
                                  return CustomCachedImage(
                                    imageUrl: item?.image != null ? '${ApiConstants.baseUrl}${item!.image}' : null,
                                    placeholder: const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                                    errorWidget: const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                                  );
                                }),
                              ))),
                      const SizedBox(height: 16),
                      if (_categories.isNotEmpty)
                        DropdownButtonFormField<int>(
                          value: selectedCategoryId,
                          items: _categories.map((cat) => DropdownMenuItem<int>(value: cat.id, child: Text(cat.name))).toList(),
                          onChanged: (val) => setStateDialog(() => selectedCategoryId = val),
                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: costPriceController, decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)
                    ])),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate() || selectedCategoryId == null) return;
                      Navigator.pop(dialogContext);
                      _saveMenuItem(item: item, name: nameController.text, price: double.parse(priceController.text), costPrice: double.parse(costPriceController.text), stock: int.parse(stockController.text), categoryId: selectedCategoryId!, image: pickedImage);
                    },
                    child: const Text('Save'))
              ],
            )));
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    // FINAL FIX: The DefaultTabController now wraps the ENTIRE Scaffold.
    // This makes the controller available to all descendant widgets, including the FloatingActionButton.
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Menu'),
          actions: [
            if (!_isLoading)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'add_category') _showAddCategoryDialog();
                  if (value == 'manage_categories') _showManageCategoriesDialog();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'add_category', child: Text('Add New Category')),
                  if (_categories.isNotEmpty)
                    const PopupMenuItem(value: 'manage_categories', child: Text('Manage Categories')),
                ],
              )
          ],
          // FINAL FIX: The TabBar goes in the AppBar's `bottom` property.
          // It automatically finds the DefaultTabController from its ancestor.
          bottom: _isLoading || _categories.isEmpty
              ? PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: _isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
          )
              : TabBar(
            isScrollable: true,
            tabs: _categories.map((c) => Tab(text: c.name)).toList(),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: _isLoading
            ? null
            : Builder( // Use a builder to get the correct context
          builder: (ctx) => FloatingActionButton.extended(
              onPressed: _categories.isEmpty
                  ? _showAddCategoryDialog
              // We pass the new context `ctx` from the Builder
                  : () => _showFoodDialog(context: ctx),
              label: Text(_categories.isEmpty ? 'Add Category' : 'Add Item'),
              icon: const Icon(Icons.add)),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _categories.isEmpty) return _buildShimmer();
    if (_errorMessage != null) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: $_errorMessage\nPlease pull down to refresh.', textAlign: TextAlign.center)));
    if (_categories.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("No categories found.\nAdd a category to begin.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _showAddCategoryDialog, icon: const Icon(Icons.add), label: const Text("Add Category")),
          ]));
    }

    // FINAL FIX: The body is now just the TabBarView.
    return TabBarView(
      children: _categories.map((category) => _buildMenuList(category)).toList(),
    );
  }

  Widget _buildMenuList(FoodCategory category) {
    final items = _foodItems.where((item) => item.categoryId == category.id).toList();
    if (items.isEmpty) return const Center(child: Text("No items in this category yet.\nTap the '+' button to add one.", textAlign: TextAlign.center));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: CustomCachedImage(imageUrl: '${ApiConstants.baseUrl}${item.image}'),
                            ),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Price: Rs. ${item.price.toStringAsFixed(2)} | Stock: ${item.stock}"),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            // FINAL FIX: Pass the item's context to the dialog.
                            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showFoodDialog(context: context, item: item)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMenuItem(item))
                          ]))),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) =>
      showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))
        ],
      ));

  Widget _buildShimmer() {
    return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 8,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Container(width: 56.0, height: 56.0, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Container(width: double.infinity, height: 10.0, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 10.0, color: Colors.white),
                ]),
              )
            ]),
          ),
        ));
  }
}