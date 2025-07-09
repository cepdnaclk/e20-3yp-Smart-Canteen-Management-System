import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/food_category.dart';
import 'package:food_app/models/menu_item.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/app_drawer.dart';
import 'package:food_app/widgets/quantity_toggle.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  List<MenuItem> _allMenuItems = [];
  List<FoodCategory> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isPlacingOrder = false;
  String? _customerName;
  late AnimationController _cartAnimationController;

  bool _isCongestionLoading = true;
  int _queueCount = 0;
  String _congestionLevel = 'Low';
  int _estimatedQueueTime = 0;

  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _fetchData();
    _fetchCustomerName();
    _fetchCongestionData();
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerName() async {
    try {
      final name = await storage.read(key: 'user_name');
      if (mounted && name != null) {
        setState(() => _customerName = name);
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchCategories(), _fetchTodaysMenu()]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) setState(() => _categories = data.map((json) => FoodCategory.fromJson(json)).toList());
      }
    } catch (e) {
      // Handle error silently in UI
    }
  }

  Future<void> _fetchTodaysMenu() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.todaysMenu),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _allMenuItems = data.map((json) => MenuItem.fromJson(json)).toList());
          context.read<CartProvider>().setMenuItems(_allMenuItems);
        }
      }
    } catch (e) {
      // Handle error silently in UI
    }
  }

  List<MenuItem> _filteredMenuItems(FoodCategory category) {
    return _allMenuItems
        .where((item) =>
    item.categoryId == category.id && (item.name.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              maxChildSize: 0.8,
              minChildSize: 0.3,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              if (cart.cartItems.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => cart.clearCart(),
                                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                                  label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: cart.cartItems.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset('assets/animations/empty_cart.json', width: 150),
                                const SizedBox(height: 16),
                                const Text("Your cart is empty!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                              ],
                            ),
                          )
                              : ListView.builder(
                            controller: scrollController,
                            itemCount: cart.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cart.cartItems[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  // --- FIX: Explicitly check if imagePath exists ---
                                  child: (item.imagePath.isNotEmpty)
                                      ? Image.network(
                                    '${ApiConstants.baseUrl}${item.imagePath}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => const Icon(Icons.fastfood, size: 50),
                                  )
                                      : const Icon(Icons.fastfood, size: 50),
                                ),
                                title: Text(item.name),
                                subtitle: Text('Rs. ${item.price.toStringAsFixed(2)}'),
                                trailing: SizedBox(
                                  width: 150,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      QuantityToggle(itemId: item.id),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => cart.clearItemFromCart(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (cart.cartItems.isNotEmpty) _buildCartFooter(cart),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartFooter(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFf0f0f0), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Rs. ${cart.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : () => _placeOrder(context),
              child: _isPlacingOrder
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext navContext) async {
    setState(() => _isPlacingOrder = true);
    final cart = Provider.of<CartProvider>(navContext, listen: false);

    final token = await storage.read(key: 'jwt_token');
    final email = await storage.read(key: 'email');

    if (token == null || email == null) {
      NotificationUtils.showAnimatedPopup(context, title: "Error", message: 'Authentication error. Please log in again.', isSuccess: false);
      setState(() => _isPlacingOrder = false);
      return;
    }

    final itemsMap = <String, int>{};
    cart.cart.forEach((menuItemId, quantity) {
      itemsMap[menuItemId.toString()] = quantity;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.placeOrder),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'items': itemsMap}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          cart.clearCart();
          Navigator.pop(navContext);
          NotificationUtils.showAnimatedPopup(
            context,
            title: 'Order Placed!',
            message: 'Your order has been sent to the canteen.',
            isSuccess: true,
          );
        } else {
          String errorMessage = 'Failed to place order.';
          try {
            final responseData = jsonDecode(response.body);
            errorMessage = responseData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = response.body;
          }
          NotificationUtils.showAnimatedPopup(context, title: "Error", message: errorMessage, isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: 'An error occurred.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _fetchCongestionData() async {
    setState(() => _isCongestionLoading = true);
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) {
        if (mounted) setState(() => _isCongestionLoading = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/canteen/congestion'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int queueCount = data['queueCount'] ?? 0;
        String level;
        if (queueCount < 10) {
          level = 'Low';
        } else if (queueCount < 25) {
          level = 'Medium';
        } else {
          level = 'High';
        }
        int estimatedTime = (queueCount * 1.5).round();
        if (mounted) {
          setState(() {
            _queueCount = queueCount;
            _congestionLevel = level;
            _estimatedQueueTime = estimatedTime;
            _isCongestionLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isCongestionLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isCongestionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hi, ${_customerName ?? 'Guest'}"),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.2).animate(CurvedAnimation(
                  parent: _cartAnimationController,
                  curve: Curves.easeOut,
                )),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => _showCart(context),
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return cart.cartItems.isEmpty
                      ? const SizedBox.shrink()
                      : Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cart.cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? _buildShimmer()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search menu items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            _buildCongestionInfo(),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final items = _filteredMenuItems(category);
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(category.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        height: 250,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: items.length,
                            itemBuilder: (context, itemIndex) {
                              final item = items[itemIndex];
                              return AnimationConfiguration.staggeredList(
                                position: itemIndex,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  horizontalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: SizedBox(
                                      width: 150,
                                      child: Card(
                                        elevation: 2,
                                        clipBehavior: Clip.antiAlias,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              // --- FIX: Explicitly check if imagePath exists ---
                                              child: (item.imagePath.isNotEmpty)
                                                  ? Image.network(
                                                '${ApiConstants.baseUrl}${item.imagePath}',
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 40)),
                                              )
                                                  : const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 40)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(item.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Text('Rs. ${item.price.toStringAsFixed(2)}', textAlign: TextAlign.center),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                              child: GestureDetector(
                                                onTap: () {
                                                  _cartAnimationController.forward().then((_) => _cartAnimationController.reverse());
                                                },
                                                child: QuantityToggle(itemId: item.id),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCongestionInfo() {
    if (_isCongestionLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: const [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 12),
            Text('Loading congestion info...'),
          ],
        ),
      );
    }
    Color levelColor;
    switch (_congestionLevel) {
      case 'High':
        levelColor = Colors.red;
        break;
      case 'Medium':
        levelColor = Colors.orange;
        break;
      default:
        levelColor = Colors.green;
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage('images/queue.png'),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCongestionStat('Congestion Level', _congestionLevel, color: levelColor),
              _buildCongestionStat('People in Queue', '$_queueCount'),
              _buildCongestionStat('Est. Wait Time', '$_estimatedQueueTime min'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCongestionStat(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(width: double.infinity, height: 50, color: Colors.white, child: const TextField()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(width: double.infinity, height: 100, color: Colors.white, child: const Card()),
          ),
          ...List.generate(
              2,
                  (index) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(width: 100, height: 20, color: Colors.white),
                  ),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 150,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Container(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
