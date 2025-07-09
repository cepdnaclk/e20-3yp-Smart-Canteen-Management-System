// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/food_category.dart';
// import 'package:food_app/models/menu_item.dart';
// import 'package:food_app/utils/notification_utils.dart';
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
// class _ManageMenuScreenState extends State<ManageMenuScreen> with SingleTickerProviderStateMixin {
//   final _storage = const FlutterSecureStorage();
//   List<FoodCategory> _categories = [];
//   List<MenuItem> _foodItems = [];
//   bool _isLoading = true;
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
//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     await Future.wait([_loadCategories(), _loadFoodItems()]);
//     _updateTabController();
//     if (mounted) setState(() => _isLoading = false);
//   }
//
//   Future<void> _loadCategories() async {
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Authorization': 'Bearer $token'});
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         _categories = data.map((json) => FoodCategory.fromJson(json)).toList();
//       }
//     } catch (e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not load categories.', isSuccess: false);
//     }
//   }
//
//   Future<void> _loadFoodItems() async {
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems), headers: {'Authorization': 'Bearer $token'});
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         _foodItems = data.map((json) => MenuItem.fromJson(json)).toList();
//       }
//     } catch (e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not load menu items.', isSuccess: false);
//     }
//   }
//
//   void _updateTabController() {
//     if (_categories.isEmpty) {
//       _tabController?.dispose();
//       _tabController = null;
//     } else if (_tabController?.length != _categories.length) {
//       final oldIndex = _tabController?.index ?? 0;
//       _tabController?.dispose();
//       _tabController = TabController(length: _categories.length, vsync: this, initialIndex: oldIndex < _categories.length ? oldIndex : 0);
//     }
//     setState(() {});
//   }
//
//   Future<String?> _uploadImage(XFile imageFile) async {
//     try {
//       final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.baseUrl + ApiConstants.uploads));
//       request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
//       final response = await request.send();
//       if (response.statusCode == 200) {
//         final responseData = await response.stream.bytesToString();
//         return jsonDecode(responseData)['filePath'];
//       }
//     } catch (e) {
//       return null;
//     }
//     return null;
//   }
//
//   Future<void> _saveMenuItem({MenuItem? item, required String name, required double price, required double costPrice, required int stock, required int categoryId, XFile? image}) async {
//     String? imagePath = item?.imagePath;
//     if (image != null) {
//       final uploadedPath = await _uploadImage(image);
//       if (uploadedPath == null) {
//         NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Image upload failed. Item not saved.", isSuccess: false);
//         return;
//       }
//       imagePath = uploadedPath;
//     }
//     if (imagePath == null && item == null) {
//       NotificationUtils.showAnimatedPopup(context, title: "Error", message: "An image is required for new items.", isSuccess: false);
//       return;
//     }
//     final body = json.encode({'id': item?.id, 'name': name, 'price': price, 'costPrice': costPrice, 'stock': stock, 'categoryId': categoryId, 'imagePath': imagePath});
//     final token = await _storage.read(key: 'jwt_token');
//     final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
//     final url = item == null ? Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems) : Uri.parse('${ApiConstants.baseUrl}${ApiConstants.menuItems}/${item.id}');
//     final response = item == null ? await http.post(url, headers: headers, body: body) : await http.put(url, headers: headers, body: body);
//     if (mounted) {
//       if (response.statusCode == 200) {
//         NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Menu item has been saved.", isSuccess: true);
//         _loadData();
//       } else {
//         NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Failed to save item. ${response.body}", isSuccess: false);
//       }
//     }
//   }
//
//   Future<void> _deleteMenuItem(MenuItem item) async {
//     final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Item?'), content: Text('Are you sure you want to delete "${item.name}"?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
//     if (confirm != true) return;
//     final token = await _storage.read(key: 'jwt_token');
//     final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.menuItems}/${item.id}'), headers: {'Authorization': 'Bearer $token'});
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
//   Future<void> _addCategory(String name) async {
//     final token = await _storage.read(key: 'jwt_token');
//     final response = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'name': name, 'description': 'A new Category', 'merchantId':7}));
//     if (mounted) {
//       if (response.statusCode == 200) {
//         NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Category "$name" added.', isSuccess: true);
//         _loadData();
//       } else {
//         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to add category.', isSuccess: false);
//       }
//     }
//   }
//
//   Future<void> _deleteCategory(FoodCategory category) async {
//     final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Category?'), content: Text('Are you sure you want to delete "${category.name}"?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
//     if (confirm != true) return;
//     final token = await _storage.read(key: 'jwt_token');
//     final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.foodCategories}/${category.id}'), headers: {'Authorization': 'Bearer $token'});
//     if (mounted) {
//       if (response.statusCode == 204 || response.statusCode == 200) {
//         NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: 'Category "${category.name}" deleted.', isSuccess: true);
//         _loadData();
//       } else {
//         NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete category. It may still contain menu items.', isSuccess: false);
//       }
//     }
//   }
//
//   void _showAddCategoryDialog() {
//     final nameController = TextEditingController();
//     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add New Category'), content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () {if (nameController.text.isNotEmpty) {Navigator.pop(context); _addCategory(nameController.text);}}, child: const Text('Add'))]));
//   }
//
//   void _showManageCategoriesDialog() {
//     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Manage Categories'), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: _categories.length, itemBuilder: (context, index) {final category = _categories[index]; return ListTile(title: Text(category.name), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {Navigator.pop(context); _deleteCategory(category);}));})), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
//   }
//
//   Future<void> _showFoodDialog({MenuItem? item}) async {
//     final formKey = GlobalKey<FormState>();
//     final nameController = TextEditingController(text: item?.name ?? '');
//     final priceController = TextEditingController(text: item?.price.toString() ?? '');
//     final costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '');
//     final stockController = TextEditingController(text: item?.stock.toString() ?? '');
//     XFile? pickedImage;
//     int selectedCategoryId = item?.categoryId ?? (_tabController != null ? _categories[_tabController!.index].id : 0);
//
//     await showDialog(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setStateDialog) => AlertDialog(title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'), content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [GestureDetector(onTap: () async {final picker = ImagePicker(); final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); if (file != null) setStateDialog(() => pickedImage = file);}, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)), child: ClipRRect(borderRadius: BorderRadius.circular(11),
//         // FIXED: This block now handles the null 'pickedImage' safely.
//         child: Builder(
//           builder: (context) {
//             final localPickedImage = pickedImage; // Create a local, non-nullable variable.
//             if (localPickedImage != null) {
//               return kIsWeb ? Image.network(localPickedImage.path, fit: BoxFit.cover) : Image.file(File(localPickedImage.path), fit: BoxFit.cover);
//             } else if (item?.imagePath.isNotEmpty ?? false) {
//               return Image.network(ApiConstants.baseUrl + ApiConstants.uploads + item!.imagePath, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.camera_alt, color: Colors.grey, size: 40));
//             } else {
//               return const Icon(Icons.camera_alt, color: Colors.grey, size: 40);
//             }
//           },
//         )
//     ))), const SizedBox(height: 16), TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null), const SizedBox(height: 12), TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null), const SizedBox(height: 12), TextFormField(controller: costPriceController, decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null), const SizedBox(height: 12), TextFormField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () {if (!formKey.currentState!.validate()) return; Navigator.pop(context); _saveMenuItem(item: item, name: nameController.text, price: double.parse(priceController.text), costPrice: double.parse(costPriceController.text), stock: int.parse(stockController.text), categoryId: selectedCategoryId, image: pickedImage);}, child: const Text('Save'))])));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Manage Menu'), actions: [PopupMenuButton<String>(onSelected: (value) {if (value == 'add_category') _showAddCategoryDialog(); if (value == 'manage_categories') _showManageCategoriesDialog();}, itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[const PopupMenuItem<String>(value: 'add_category', child: Text('Add New Category')), const PopupMenuItem<String>(value: 'manage_categories', child: Text('Manage Categories'))])], bottom: _isLoading ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator()) : (_categories.isEmpty ? null : TabBar(controller: _tabController, isScrollable: true, tabs: _categories.map((c) => Tab(text: c.name)).toList()))),
//       body: _isLoading ? _buildShimmer() : (_categories.isEmpty ? const Center(child: Text("No categories found.\nAdd a category to begin.", textAlign: TextAlign.center)) : TabBarView(controller: _tabController, children: _categories.map((category) => _buildMenuList(category)).toList())),
//       floatingActionButton: _categories.isEmpty ? null : FloatingActionButton.extended(onPressed: () => _showFoodDialog(), label: const Text('Add Item'), icon: const Icon(Icons.add)),
//     );
//   }
//
//   Widget _buildMenuList(FoodCategory category) {
//     final items = _foodItems.where((item) => item.categoryId == category.id).toList();
//     if (items.isEmpty) return const Center(child: Text("No items in this category yet."));
//     return AnimationLimiter(
//       child: ListView.builder(
//         padding: const EdgeInsets.only(bottom: 80, top: 8),
//         itemCount: items.length,
//         itemBuilder: (context, index) {
//           final item = items[index];
//           return AnimationConfiguration.staggeredList(
//             position: index,
//             duration: const Duration(milliseconds: 375),
//             child: SlideAnimation(
//               verticalOffset: 50.0,
//               child: FadeInAnimation(
//                 child: Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ApiConstants.baseUrl + ApiConstants.uploads + item.imagePath, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 30))), title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Price: Rs. ${item.price.toStringAsFixed(2)} | Stock: ${item.stock}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showFoodDialog(item: item)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMenuItem(item))]))),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildShimmer() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: ListView(children: [Container(height: 50, color: Colors.white, margin: const EdgeInsets.all(8)), ...List.generate(5, (index) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.white), title: Container(height: 10, color: Colors.white), subtitle: Container(height: 10, color: Colors.white, width: 50))))]),
//     );
//   }
// }

// File: lib/screens/merchant/manage_menu_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for the web check
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/food_category.dart';
import 'package:food_app/models/menu_item.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<FoodCategory> _categories = [];
  List<MenuItem> _foodItems = [];
  bool _isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadCategories(), _loadFoodItems()]);
    _updateTabController();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if(mounted) setState(() => _categories = data.map((json) => FoodCategory.fromJson(json)).toList());
      }
    } catch (e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not load categories.', isSuccess: false);
    }
  }

  Future<void> _loadFoodItems() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if(mounted) setState(() => _foodItems = data.map((json) => MenuItem.fromJson(json)).toList());
      }
    } catch (e) {
      if(mounted) NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Could not load menu items.', isSuccess: false);
    }
  }

  void _updateTabController() {
    if (_categories.isEmpty) {
      _tabController?.dispose();
      _tabController = null;
    } else if (_tabController?.length != _categories.length) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(length: _categories.length, vsync: this, initialIndex: oldIndex < _categories.length ? oldIndex : 0);
    }
    if(mounted) setState(() {});
  }

  // --- FIX: Corrected upload function to work on both web and mobile ---
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final url = Uri.parse('${ApiConstants.baseUrl}/api/uploads');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        // For web, read bytes and use fromBytes
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name, // Pass the filename for the backend
        ));
      } else {
        // For mobile/desktop, fromPath is correct
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        // Backend returns the full relative path as plain text
        final responseData = await response.stream.bytesToString();
        return responseData;
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint("Image upload failed with status ${response.statusCode}: $errorBody");
        return null;
      }
    } catch (e) {
      debugPrint("Image upload exception: $e");
      return null;
    }
  }

  Future<void> _saveMenuItem({MenuItem? item, required String name, required double price, required double costPrice, required int stock, required int categoryId, XFile? image}) async {
    String? imagePath = item?.imagePath;
    if (image != null) {
      final uploadedPath = await _uploadImage(image);
      if (uploadedPath == null) {
        NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Image upload failed. Item not saved.", isSuccess: false);
        return;
      }
      imagePath = uploadedPath;
    }
    if (imagePath == null && item == null) {
      NotificationUtils.showAnimatedPopup(context, title: "Error", message: "An image is required for new items.", isSuccess: false);
      return;
    }
    final body = json.encode({'id': item?.id, 'name': name, 'price': price, 'costPrice': costPrice, 'stock': stock, 'categoryId': categoryId, 'imagePath': imagePath});
    final token = await _storage.read(key: 'jwt_token');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    final url = item == null ? Uri.parse(ApiConstants.baseUrl + ApiConstants.menuItems) : Uri.parse('${ApiConstants.baseUrl}${ApiConstants.menuItems}/${item.id}');
    final response = item == null ? await http.post(url, headers: headers, body: body) : await http.put(url, headers: headers, body: body);
    if (mounted) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        NotificationUtils.showAnimatedPopup(context, title: "Success", message: "Menu item has been saved.", isSuccess: true);
        _loadData();
      } else {
        NotificationUtils.showAnimatedPopup(context, title: "Error", message: "Failed to save item. ${response.body}", isSuccess: false);
      }
    }
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Item?'), content: Text('Are you sure you want to delete "${item.name}"?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
    if (confirm != true) return;
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.menuItems}/${item.id}'), headers: {'Authorization': 'Bearer $token'});
    if (mounted) {
      if (response.statusCode == 204 || response.statusCode == 200) {
        NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: '${item.name} has been deleted.', isSuccess: true);
        _loadData();
      } else {
        NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete item. It might be in use.', isSuccess: false);
      }
    }
  }

  Future<void> _addCategory(String name) async {
    final token = await _storage.read(key: 'jwt_token');
    final body = json.encode({'name': name, 'description': 'A new Category','merchantId':7});
    final response = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: body);
    if (mounted) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        NotificationUtils.showAnimatedPopup(context, title: 'Success', message: 'Category "$name" added.', isSuccess: true);
        _loadData();
      } else {
        NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to add category.', isSuccess: false);
      }
    }
  }

  Future<void> _deleteCategory(FoodCategory category) async {
    final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Category?'), content: Text('Are you sure you want to delete "${category.name}"?'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
    if (confirm != true) return;
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.foodCategories}/${category.id}'), headers: {'Authorization': 'Bearer $token'});
    if (mounted) {
      if (response.statusCode == 204 || response.statusCode == 200) {
        NotificationUtils.showAnimatedPopup(context, title: 'Deleted', message: 'Category "${category.name}" deleted.', isSuccess: true);
        _loadData();
      } else {
        NotificationUtils.showAnimatedPopup(context, title: 'Error', message: 'Failed to delete category. It may still contain menu items.', isSuccess: false);
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add New Category'), content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () {if (nameController.text.isNotEmpty) {Navigator.pop(context); _addCategory(nameController.text);}}, child: const Text('Add'))]));
  }

  void _showManageCategoriesDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Manage Categories'), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: _categories.length, itemBuilder: (context, index) {final category = _categories[index]; return ListTile(title: Text(category.name), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {Navigator.pop(context); _deleteCategory(category);}));})), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  Future<void> _showFoodDialog({MenuItem? item}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '');
    final stockController = TextEditingController(text: item?.stock.toString() ?? '');
    XFile? pickedImage;
    int? selectedCategoryId = item?.categoryId;
    if (selectedCategoryId == null && _categories.isNotEmpty) {
      selectedCategoryId = _categories[_tabController?.index ?? 0].id;
    }

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
              title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                            if (file != null) setStateDialog(() => pickedImage = file);
                          },
                          child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                // --- FIX: Correctly display preview on web and mobile ---
                                child: Builder(
                                  builder: (context) {
                                    if (pickedImage != null) {
                                      // Use Image.network for web preview, Image.file for mobile
                                      return kIsWeb ? Image.network(pickedImage!.path, fit: BoxFit.cover) : Image.file(File(pickedImage!.path), fit: BoxFit.cover);
                                    } else if (item?.imagePath.isNotEmpty ?? false) {
                                      // Construct the full URL for existing images
                                      return Image.network('${ApiConstants.baseUrl}${item!.imagePath}', fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.camera_alt, color: Colors.grey, size: 40));
                                    } else {
                                      return const Icon(Icons.camera_alt, color: Colors.grey, size: 40);
                                    }
                                  },
                                ),
                              ))),
                      const SizedBox(height: 16),
                      if (_categories.isNotEmpty)
                        DropdownButtonFormField<int>(
                          value: selectedCategoryId,
                          items: _categories.map((FoodCategory category) {
                            return DropdownMenuItem<int>(value: category.id, child: Text(category.name));
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) setStateDialog(() => selectedCategoryId = newValue);
                          },
                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          validator: (value) => value == null ? 'Please select a category' : null,
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate() || selectedCategoryId == null) return;
                      Navigator.pop(context);
                      _saveMenuItem(
                          item: item,
                          name: nameController.text,
                          price: double.parse(priceController.text),
                          costPrice: double.parse(costPriceController.text),
                          stock: int.parse(stockController.text),
                          categoryId: selectedCategoryId!,
                          image: pickedImage);
                    },
                    child: const Text('Save'))
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_category') _showAddCategoryDialog();
              if (value == 'manage_categories') _showManageCategoriesDialog();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'add_category', child: Text('Add New Category')),
              const PopupMenuItem<String>(value: 'manage_categories', child: Text('Manage Categories')),
            ],
          )
        ],
        bottom: _isLoading
            ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator())
            : (_categories.isEmpty
            ? null
            : TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: c.name)).toList(),
        )),
      ),
      body: _isLoading
          ? _buildShimmer()
          : (_categories.isEmpty
          ? const Center(child: Text("No categories found.\nAdd a category to begin.", textAlign: TextAlign.center))
          : TabBarView(
        controller: _tabController,
        children: _categories.map((category) => _buildMenuList(category)).toList(),
      )),
      floatingActionButton: _categories.isEmpty ? null : FloatingActionButton.extended(onPressed: () => _showFoodDialog(), label: const Text('Add Item'), icon: const Icon(Icons.add)),
    );
  }

  Widget _buildMenuList(FoodCategory category) {
    final items = _foodItems.where((item) => item.categoryId == category.id).toList();
    if (items.isEmpty) return const Center(child: Text("No items in this category yet."));
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            // --- FIX: Correctly construct the full image URL ---
                            child: Image.network('${ApiConstants.baseUrl}${item.imagePath}', width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 30))),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Price: Rs. ${item.price.toStringAsFixed(2)} | Stock: ${item.stock}"),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showFoodDialog(item: item)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMenuItem(item))
                        ]))),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(children: [
        Container(height: 50, color: Colors.white, margin: const EdgeInsets.all(8)),
        ...List.generate(
            5,
                (index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(leading: CircleAvatar(backgroundColor: Colors.white), title: Container(height: 10, color: Colors.white), subtitle: Container(height: 10, color: Colors.white, width: 50))))
      ]),
    );
  }
}