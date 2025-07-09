import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Manager',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const FoodManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FoodItem {
  String name;
  String imagePath; // local file path or network URL
  double price;
  String category;

  FoodItem({
    required this.name,
    required this.imagePath,
    required this.price,
    required this.category,
  });
}

class FoodManagementScreen extends StatefulWidget {
  const FoodManagementScreen({super.key});

  @override
  State<FoodManagementScreen> createState() => _FoodManagementScreenState();
}

class _FoodManagementScreenState extends State<FoodManagementScreen>
    with SingleTickerProviderStateMixin {
  final List<String> categories = [
    'Breakfast',
    'Lunch',
    'Snacks',
    'Dinner',
    'Beverages',
  ];
  final List<FoodItem> foodItems = [];

  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    _tabController = TabController(length: categories.length, vsync: this);
    super.initState();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  void _showFoodDialog({FoodItem? item, required String category}) {
    final nameController = TextEditingController(text: item?.name);
    final priceController = TextEditingController(text: item?.price.toString());
    _selectedImage =
        item != null && item.imagePath.startsWith('/')
            ? XFile(item.imagePath)
            : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (ctx, setModalState) => AlertDialog(
                  title: Text(item == null ? 'Add Food' : 'Edit Food'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            showModalBottomSheet(
                              context: context,
                              builder:
                                  (context) => Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo),
                                        title: const Text(
                                          'Choose from Gallery',
                                        ),
                                        onTap: () async {
                                          await _pickImage(false);
                                          setModalState(() {});
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.camera),
                                        title: const Text('Take a Photo'),
                                        onTap: () async {
                                          await _pickImage(true);
                                          setModalState(() {});
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                            );
                          },
                          child:
                              _selectedImage != null
                                  ? Image.file(
                                    File(_selectedImage!.path),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                  : item != null &&
                                      !item.imagePath.startsWith('/')
                                  ? Image.network(
                                    item.imagePath,
                                    height: 100,
                                    width: 100,
                                  )
                                  : Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Food Name',
                          ),
                        ),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _selectedImage = null;
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final newItem = FoodItem(
                          name: nameController.text,
                          imagePath:
                              _selectedImage?.path ?? item?.imagePath ?? '',
                          price: double.tryParse(priceController.text) ?? 0.0,
                          category: category,
                        );
                        setState(() {
                          if (item != null) {
                            foodItems.remove(item);
                          }
                          foodItems.add(newItem);
                          _selectedImage = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(item == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteFood(FoodItem item) {
    setState(() {
      foodItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Canteen - Food Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: categories.map((c) => Tab(text: c)).toList(),
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            categories.map((category) {
              final filteredItems =
                  foodItems.where((f) => f.category == category).toList();
              return filteredItems.isEmpty
                  ? const Center(child: Text('No items yet'))
                  : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final imageWidget =
                          item.imagePath.startsWith('/')
                              ? Image.file(
                                File(item.imagePath),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                              : Image.network(
                                item.imagePath,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(Icons.fastfood),
                              );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: imageWidget,
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            'Rs. ${item.price.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed:
                                    () => _showFoodDialog(
                                      item: item,
                                      category: category,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteFood(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
            }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentCategory = categories[_tabController.index];
          _showFoodDialog(category: currentCategory);
        },
        label: const Text('Add Food'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
