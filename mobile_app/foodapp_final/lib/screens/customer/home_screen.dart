
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/food_category.dart';
// import 'package:food_app/models/menu_item.dart';
// import 'package:food_app/providers/cart_provider.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:food_app/widgets/app_drawer.dart';
// import 'package:food_app/widgets/quantity_toggle.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:lottie/lottie.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   final storage = const FlutterSecureStorage();
//   List<MenuItem> _allMenuItems = [];
//   List<FoodCategory> _categories = [];
//   String? _errorMessage;
//
//   bool _isLoading = true;
//   String _searchQuery = '';
//   bool _isPlacingOrder = false;
//   String? _customerName;
//   late AnimationController _cartAnimationController;
//   Timer? _congestionTimer;
//
//   // Congestion State
//   bool _isCongestionLoading = true;
//   int _queueCount = 0;
//   String _congestionLevel = 'Low';
//   int _estimatedQueueTime = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _cartAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _initializeScreen();
//
//     // Fetch congestion data periodically
//     _congestionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (mounted) _fetchCongestionData();
//     });
//   }
//
//   @override
//   void dispose() {
//     _cartAnimationController.dispose();
//     _congestionTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _initializeScreen() async {
//     _fetchCustomerName();
//     await _fetchData();
//     await _fetchCongestionData();
//   }
//
//   Future<void> _fetchCustomerName() async {
//     final name = await storage.read(key: 'user_name');
//     if (mounted && name != null) {
//       setState(() => _customerName = name);
//     }
//   }
//
//   Future<void> _fetchData() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       if (token == null) throw Exception('Authentication failed. Please log in again.');
//
//       final headers = {'Authorization': 'Bearer $token'};
//       final categoriesFuture = http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories), headers: headers);
//       final menuFuture = http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.todaysMenu), headers: headers);
//
//       final responses = await Future.wait([categoriesFuture, menuFuture]);
//
//       if (mounted) {
//         if (responses[0].statusCode == 200) {
//           final List catData = jsonDecode(responses[0].body);
//           _categories = catData.map((json) => FoodCategory.fromJson(json)).toList();
//         } else {
//           throw Exception('Failed to load food categories.');
//         }
//
//         if (responses[1].statusCode == 200) {
//           final List menuData = jsonDecode(responses[1].body);
//           _allMenuItems = menuData.map((json) => MenuItem.fromJson(json)).toList();
//           context.read<CartProvider>().setMenuItems(_allMenuItems);
//         } else {
//           throw Exception("Failed to load today's menu.");
//         }
//       }
//     } catch (e) {
//       if (mounted) setState(() => _errorMessage = e.toString());
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _fetchCongestionData() async {
//     if (!mounted) return;
//     setState(() => _isCongestionLoading = true);
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       if (token == null) return;
//
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.canteenCongestion),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (mounted && response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _queueCount = data['queueCount'] ?? 0;
//           _congestionLevel = data['congestionLevel'] ?? 'Low';
//           _estimatedQueueTime = data['estimatedWaitTime'] ?? 0;
//         });
//       }
//     } catch (e) {
//       // Fail silently for congestion data
//     } finally {
//       if(mounted) setState(() => _isCongestionLoading = false);
//     }
//   }
//
//   Future<void> _placeOrder(BuildContext navContext) async {
//     setState(() => _isPlacingOrder = true);
//     final cart = Provider.of<CartProvider>(navContext, listen: false);
//     final token = await storage.read(key: 'jwt_token');
//     final email = await storage.read(key: 'email');
//
//     if (token == null || email == null) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: 'Authentication error. Please log in again.', isSuccess: false);
//       setState(() => _isPlacingOrder = false);
//       return;
//     }
//
//     final itemsMap = <String, int>{};
//     cart.cart.forEach((menuItemId, quantity) {
//       itemsMap[menuItemId.toString()] = quantity;
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.placeOrder),
//         headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
//         body: jsonEncode({'email': email, 'items': itemsMap}),
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           cart.clearCart();
//           Navigator.pop(navContext); // Close cart bottom sheet
//           NotificationUtils.showAnimatedPopup(context, title: 'Order Placed!', message: 'Your order has been sent to the canteen.', isSuccess: true);
//         } else {
//           final error = jsonDecode(response.body)['message'] ?? 'Failed to place order.';
//           NotificationUtils.showAnimatedPopup(context, title: "Error", message: error, isSuccess: false);
//         }
//       }
//     } catch (e) {
//       if(mounted) NotificationUtils.showAnimatedPopup(context, title: "Error", message: 'Could not connect to the server.', isSuccess: false);
//     } finally {
//       if(mounted) setState(() => _isPlacingOrder = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Hi, ${_customerName ?? 'Guest'}"),
//         actions: [_buildCartIcon()],
//       ),
//       drawer: const AppDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _fetchData,
//         child: _buildBody(),
//       ),
//     );
//   }
//
//   // --- UI Building Methods ---
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return _buildShimmer();
//     }
//     if (_errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Text('Error: $_errorMessage\nPlease pull down to refresh.', textAlign: TextAlign.center),
//         ),
//       );
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSearchField(),
//         _buildCongestionInfo(),
//         Expanded(child: _buildMenu()),
//       ],
//     );
//   }
//
//   Widget _buildMenu() {
//     if (_categories.isEmpty) {
//       return const Center(child: Text('No food categories available today.'));
//     }
//     return ListView.builder(
//       itemCount: _categories.length,
//       itemBuilder: (context, index) {
//         final category = _categories[index];
//         final items = _allMenuItems
//             .where((item) => item.categoryId == category.id && item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
//             .toList();
//
//         if (items.isEmpty) return const SizedBox.shrink();
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
//               child: Text(category.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
//             ),
//             SizedBox(
//               height: 250,
//               child: AnimationLimiter(
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   itemCount: items.length,
//                   itemBuilder: (context, itemIndex) {
//                     return AnimationConfiguration.staggeredList(
//                       position: itemIndex,
//                       duration: const Duration(milliseconds: 375),
//                       child: SlideAnimation(
//                         horizontalOffset: 50.0,
//                         child: FadeInAnimation(child: _buildMenuItemCard(items[itemIndex])),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildMenuItemCard(MenuItem item) {
//     return SizedBox(
//       width: 160,
//       child: Card(
//         elevation: 3,
//         clipBehavior: Clip.antiAlias,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               flex: 3,
//               child: (item.imagePath.isNotEmpty)
//                   ? Image.network(
//                 // FIX: Correctly construct the full image URL
//                 // '${ApiConstants.baseUrl}${ApiConstants.uploads}${item.imagePath}',
//                 '${ApiConstants.baseUrl}${item.imagePath}',
//                 fit: BoxFit.cover,
//
//
//                 errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 40)),
//               )
//                   : const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 40)),
//             ),
//             Expanded(
//               flex: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     Text('Rs. ${item.price.toStringAsFixed(2)}'),
//                     GestureDetector(
//                       onTap: () => _cartAnimationController.forward().then((_) => _cartAnimationController.reverse()),
//                       child: QuantityToggle(itemId: item.id),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showCart(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Consumer<CartProvider>(
//           builder: (context, cart, child) {
//             return DraggableScrollableSheet(
//               expand: false, initialChildSize: 0.5, maxChildSize: 0.8, minChildSize: 0.3,
//               builder: (BuildContext context, ScrollController scrollController) {
//                 return Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
//                     child: Column(
//                       children: [
//                         // Grabber handle, title, and clear button
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 8),
//                                 decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
//                               )
//                             ],
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               const Text('Your Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                               if (cart.cartItems.isNotEmpty)
//                                 TextButton.icon(
//                                   onPressed: () => cart.clearCart(),
//                                   icon: const Icon(Icons.delete_sweep, color: Colors.red),
//                                   label: const Text('Clear All', style: TextStyle(color: Colors.red)),
//                                 ),
//                             ],
//                           ),
//                         ),
//                         const Divider(),
//                         // Cart items or empty message
//                         Expanded(
//                           child: cart.cartItems.isEmpty
//                               ? _buildEmptyCart()
//                               : ListView.builder(
//                             controller: scrollController,
//                             itemCount: cart.cartItems.length,
//                             itemBuilder: (context, index) {
//                               final item = cart.cartItems[index];
//                               return ListTile(
//                                 leading: ClipRRect(
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: (item.imagePath.isNotEmpty)
//                                       ? Image.network(
//                                     // FIX: Correctly construct the full image URL
//                                     '${ApiConstants.baseUrl}${ApiConstants.uploads}${item.imagePath}',
//                                     width: 50, height: 50, fit: BoxFit.cover,
//                                     errorBuilder: (ctx, err, st) => const Icon(Icons.fastfood, size: 50),
//                                   )
//                                       : const Icon(Icons.fastfood, size: 50),
//                                 ),
//                                 title: Text(item.name),
//                                 subtitle: Text('Rs. ${item.price.toStringAsFixed(2)}'),
//                                 trailing: SizedBox(
//                                   width: 150,
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       QuantityToggle(itemId: item.id),
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.red),
//                                         onPressed: () => cart.clearItemFromCart(item.id),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         if (cart.cartItems.isNotEmpty) _buildCartFooter(cart),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildEmptyCart() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Lottie.asset('assets/animations/empty_cart.json', width: 150),
//           const SizedBox(height: 16),
//           const Text("Your cart is empty!", style: TextStyle(fontSize: 18, color: Colors.grey)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCartFooter(CartProvider cart) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Color(0xFFf0f0f0), width: 1)),
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               Text('Rs. ${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
//             ],
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               onPressed: _isPlacingOrder ? null : () => _placeOrder(context),
//               child: _isPlacingOrder
//                   ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
//                   : const Text('Place Order'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCartIcon() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         ScaleTransition(
//           scale: Tween(begin: 1.0, end: 1.2).animate(CurvedAnimation(
//             parent: _cartAnimationController,
//             curve: Curves.easeOut,
//           )),
//           child: IconButton(
//             icon: const Icon(Icons.shopping_cart_outlined),
//             onPressed: () => _showCart(context),
//           ),
//         ),
//         Consumer<CartProvider>(
//           builder: (context, cart, child) {
//             return cart.cartItems.isEmpty
//                 ? const SizedBox.shrink()
//                 : Positioned(
//               right: 8, top: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text('${cart.cartItems.length}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSearchField() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: TextField(
//         onChanged: (value) => setState(() => _searchQuery = value),
//         decoration: InputDecoration(
//           hintText: 'Search menu items...',
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
//           filled: true,
//           fillColor: Colors.grey.shade200,
//           contentPadding: EdgeInsets.zero,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCongestionInfo() {
//     if (_isCongestionLoading) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//         child: SizedBox(height: 40, child: Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Loading congestion info...')])),
//       );
//     }
//
//     Color levelColor;
//     switch (_congestionLevel) {
//       case 'High': levelColor = Colors.red; break;
//       case 'Medium': levelColor = Colors.orange; break;
//       default: levelColor = Colors.green;
//     }
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildCongestionStat('Congestion', _congestionLevel, color: levelColor),
//             _buildCongestionStat('Queue', '$_queueCount'),
//             _buildCongestionStat('Wait Time', '$_estimatedQueueTime min'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCongestionStat(String title, String value, {Color? color}) {
//     return Column(
//       children: [
//         Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
//         const SizedBox(height: 4),
//         Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Theme.of(context).textTheme.bodyLarge?.color)),
//       ],
//     );
//   }
//
//   Widget _buildShimmer() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: ListView(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
//           ),
//           ...List.generate(2, (index) => Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
//                 child: Container(width: 120, height: 24, color: Colors.white),
//               ),
//               SizedBox(
//                 height: 250,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   itemCount: 3,
//                   itemBuilder: (context, index) {
//                     return SizedBox(
//                       width: 160,
//                       child: Card(
//                         margin: const EdgeInsets.symmetric(horizontal: 4),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                         child: Container(color: Colors.white),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           )),
//         ],
//       ),
//     );
//   }
// }





// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/food_category.dart';
// import 'package:food_app/models/menu_item.dart';
// import 'package:food_app/providers/cart_provider.dart';
// import 'package:food_app/utils/notification_utils.dart';
// import 'package:food_app/widgets/app_drawer.dart';
// import 'package:food_app/widgets/custom_cached_image.dart'; // FIX: Import the new caching widget
// import 'package:food_app/widgets/quantity_toggle.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:lottie/lottie.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   final storage = const FlutterSecureStorage();
//   List<MenuItem> _allMenuItems = [];
//   List<FoodCategory> _categories = [];
//   String? _errorMessage;
//
//   bool _isLoading = true;
//   String _searchQuery = '';
//   bool _isPlacingOrder = false;
//   String? _customerName;
//   late AnimationController _cartAnimationController;
//   Timer? _congestionTimer;
//
//   bool _isCongestionLoading = true;
//   int _queueCount = 0;
//   String _congestionLevel = 'Low';
//   int _estimatedQueueTime = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _cartAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _initializeScreen();
//
//     _congestionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (mounted) _fetchCongestionData();
//     });
//   }
//
//   @override
//   void dispose() {
//     _cartAnimationController.dispose();
//     _congestionTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _initializeScreen() async {
//     _fetchCustomerName();
//     await _fetchData();
//     await _fetchCongestionData();
//   }
//
//   Future<void> _fetchCustomerName() async {
//     final name = await storage.read(key: 'user_name');
//     if (mounted && name != null) {
//       setState(() => _customerName = name);
//     }
//   }
//
//   Future<void> _fetchData() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       if (token == null) {
//         throw Exception('Authentication failed. Please log in again.');
//       }
//
//       final headers = {'Authorization': 'Bearer $token'};
//       final categoriesFuture = http.get(
//           Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
//           headers: headers);
//       final menuFuture = http.get(
//           Uri.parse(ApiConstants.baseUrl + ApiConstants.todaysMenu),
//           headers: headers);
//
//       final responses = await Future.wait([categoriesFuture, menuFuture]);
//
//       if (mounted) {
//         if (responses[0].statusCode == 200) {
//           final List catData = jsonDecode(responses[0].body);
//           _categories =
//               catData.map((json) => FoodCategory.fromJson(json)).toList();
//         } else {
//           throw Exception('Failed to load food categories.');
//         }
//
//         if (responses[1].statusCode == 200) {
//           final List menuData = jsonDecode(responses[1].body);
//           _allMenuItems =
//               menuData.map((json) => MenuItem.fromJson(json)).toList();
//           context.read<CartProvider>().setMenuItems(_allMenuItems);
//         } else {
//           throw Exception("Failed to load today's menu.");
//         }
//       }
//     } catch (e) {
//       if (mounted) setState(() => _errorMessage = e.toString());
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _fetchCongestionData() async {
//     if (!mounted) return;
//     setState(() => _isCongestionLoading = true);
//     try {
//       final token = await storage.read(key: 'jwt_token');
//       if (token == null) return;
//
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.canteenCongestion),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (mounted && response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _queueCount = data['queueCount'] ?? 0;
//           _congestionLevel = data['congestionLevel'] ?? 'Low';
//           _estimatedQueueTime = data['estimatedWaitTime'] ?? 0;
//         });
//       }
//     } catch (e) {
//       // Fail silently
//     } finally {
//       if (mounted) setState(() => _isCongestionLoading = false);
//     }
//   }
//
//   Future<void> _placeOrder(BuildContext navContext) async {
//     setState(() => _isPlacingOrder = true);
//     final cart = Provider.of<CartProvider>(navContext, listen: false);
//     final token = await storage.read(key: 'jwt_token');
//     final email = await storage.read(key: 'email');
//
//     if (token == null || email == null) {
//       if (mounted) {
//         NotificationUtils.showAnimatedPopup(context,
//             title: "Error",
//             message: 'Authentication error. Please log in again.',
//             isSuccess: false);
//       }
//       setState(() => _isPlacingOrder = false);
//       return;
//     }
//
//     final itemsMap = <String, int>{};
//     cart.cart.forEach((menuItemId, quantity) {
//       itemsMap[menuItemId.toString()] = quantity;
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.placeOrder),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json'
//         },
//         body: jsonEncode({'email': email, 'items': itemsMap}),
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           cart.clearCart();
//           Navigator.pop(navContext); // Close cart bottom sheet
//           NotificationUtils.showAnimatedPopup(context,
//               title: 'Order Placed!',
//               message: 'Your order has been sent to the canteen.',
//               isSuccess: true);
//         } else {
//           final error =
//               jsonDecode(response.body)['message'] ?? 'Failed to place order.';
//           NotificationUtils.showAnimatedPopup(context,
//               title: "Error", message: error, isSuccess: false);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         NotificationUtils.showAnimatedPopup(context,
//             title: "Error",
//             message: 'Could not connect to the server.',
//             isSuccess: false);
//       }
//     } finally {
//       if (mounted) setState(() => _isPlacingOrder = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Hi, ${_customerName ?? 'Guest'}"),
//         actions: [_buildCartIcon()],
//       ),
//       drawer: const AppDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _fetchData,
//         child: _buildBody(),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return _buildShimmer();
//     }
//     if (_errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Text('Error: $_errorMessage\nPlease pull down to refresh.',
//               textAlign: TextAlign.center),
//         ),
//       );
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSearchField(),
//         _buildCongestionInfo(),
//         Expanded(child: _buildMenu()),
//       ],
//     );
//   }
//
//   Widget _buildMenu() {
//     if (_categories.isEmpty) {
//       return const Center(child: Text('No food categories available today.'));
//     }
//     return ListView.builder(
//       itemCount: _categories.length,
//       itemBuilder: (context, index) {
//         final category = _categories[index];
//         final items = _allMenuItems
//             .where((item) =>
//         item.categoryId == category.id &&
//             item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
//             .toList();
//
//         if (items.isEmpty) return const SizedBox.shrink();
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
//               child: Text(category.name,
//                   style: Theme.of(context)
//                       .textTheme
//                       .headlineSmall
//                       ?.copyWith(fontWeight: FontWeight.bold)),
//             ),
//             SizedBox(
//               height: 250,
//               child: AnimationLimiter(
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   itemCount: items.length,
//                   itemBuilder: (context, itemIndex) {
//                     return AnimationConfiguration.staggeredList(
//                       position: itemIndex,
//                       duration: const Duration(milliseconds: 375),
//                       child: SlideAnimation(
//                         horizontalOffset: 50.0,
//                         child: FadeInAnimation(
//                             child: _buildMenuItemCard(items[itemIndex])),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildMenuItemCard(MenuItem item) {
//     return SizedBox(
//       width: 160,
//       child: Card(
//         elevation: 3,
//         clipBehavior: Clip.antiAlias,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               flex: 3,
//               // FIX: Use the new caching widget. It will show a shimmer effect while loading.
//               child: CustomCachedImage(
//                 imageUrl: '${ApiConstants.baseUrl}${item.image}',
//               ),
//             ),
//             Expanded(
//               flex: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(item.name,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontWeight: FontWeight.bold)),
//                     Text('Rs. ${item.price.toStringAsFixed(2)}'),
//                     GestureDetector(
//                       onTap: () => _cartAnimationController.forward().then((_) =>
//                           _cartAnimationController.reverse()),
//                       child: QuantityToggle(itemId: item.id),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/food_category.dart';
import 'package:food_app/models/menu_item.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:food_app/widgets/app_drawer.dart';
import 'package:food_app/widgets/custom_cached_image.dart';
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
  String? _errorMessage;

  bool _isLoading = true;
  String _searchQuery = '';
  bool _isPlacingOrder = false;
  String? _customerName;
  late AnimationController _cartAnimationController;
  Timer? _congestionTimer;

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
    );
    _initializeScreen();

    _congestionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _fetchCongestionData();
    });
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    _congestionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    _fetchCustomerName();
    await _fetchData();
    await _fetchCongestionData();
  }

  Future<void> _fetchCustomerName() async {
    final name = await storage.read(key: 'user_name');
    if (mounted && name != null) {
      setState(() => _customerName = name);
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('Authentication failed. Please log in again.');
      }

      final headers = {'Authorization': 'Bearer $token'};
      final categoriesFuture = http.get(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.foodCategories),
          headers: headers);
      final menuFuture = http.get(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.todaysMenu),
          headers: headers);

      final responses = await Future.wait([categoriesFuture, menuFuture]);

      if (mounted) {
        if (responses[0].statusCode == 200) {
          final List catData = jsonDecode(responses[0].body);
          _categories =
              catData.map((json) => FoodCategory.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load food categories.');
        }

        if (responses[1].statusCode == 200) {
          final List menuData = jsonDecode(responses[1].body);
          _allMenuItems =
              menuData.map((json) => MenuItem.fromJson(json)).toList();
          context.read<CartProvider>().setMenuItems(_allMenuItems);
        } else {
          throw Exception("Failed to load today's menu.");
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCongestionData() async {
    if (!mounted) return;
    setState(() => _isCongestionLoading = true);
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.canteenCongestion),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _queueCount = data['queueCount'] ?? 0;
          _congestionLevel = data['congestionLevel'] ?? 'Low';
          _estimatedQueueTime = data['estimatedWaitTime'] ?? 0;
        });
      }
    } catch (e) {
      // Fail silently
    } finally {
      if (mounted) setState(() => _isCongestionLoading = false);
    }
  }

  Future<void> _placeOrder(BuildContext navContext) async {
    setState(() => _isPlacingOrder = true);
    final cart = Provider.of<CartProvider>(navContext, listen: false);
    final token = await storage.read(key: 'jwt_token');
    final email = await storage.read(key: 'email');

    if (token == null || email == null) {
      if (mounted) {
        NotificationUtils.showAnimatedPopup(context,
            title: "Error",
            message: 'Authentication error. Please log in again.',
            isSuccess: false);
      }
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
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'email': email, 'items': itemsMap}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          cart.clearCart();
          Navigator.pop(navContext); // Close cart bottom sheet
          NotificationUtils.showAnimatedPopup(context,
              title: 'Order Placed!',
              message: 'Your order has been sent to the canteen.',
              isSuccess: true);
        } else {
          final error =
              jsonDecode(response.body)['message'] ?? 'Failed to place order.';
          NotificationUtils.showAnimatedPopup(context,
              title: "Error", message: error, isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showAnimatedPopup(context,
            title: "Error",
            message: 'Could not connect to the server.',
            isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hi, ${_customerName ?? 'Guest'}"),
        actions: [_buildCartIcon()],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmer();
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Error: $_errorMessage\nPlease pull down to refresh.',
              textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        _buildCongestionInfo(),
        Expanded(child: _buildMenu()),
      ],
    );
  }

  Widget _buildMenu() {
    if (_categories.isEmpty) {
      return const Center(child: Text('No food categories available today.'));
    }
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final items = _allMenuItems
            .where((item) =>
        item.categoryId == category.id &&
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(category.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 250,
              child: AnimationLimiter(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, itemIndex) {
                    return AnimationConfiguration.staggeredList(
                      position: itemIndex,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                            child: _buildMenuItemCard(items[itemIndex])),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: CustomCachedImage(
                imageUrl: '${ApiConstants.baseUrl}${item.image}',
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // FIX: Wrap the Column in a SingleChildScrollView to prevent overflow
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 2, // Allow for two lines for longer names
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4), // Add some space
                      Text('Rs. ${item.price.toStringAsFixed(2)}'),
                      const SizedBox(height: 4), // Add some space
                      GestureDetector(
                        onTap: () => _cartAnimationController.forward().then((_) =>
                            _cartAnimationController.reverse()),
                        child: QuantityToggle(itemId: item.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// The rest of the file (_showCart, _buildCartIcon, etc.) remains the same.
// I have omitted it here for brevity.


































////////////////////////////////////////////////////////////////////////////to here

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
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewPadding.bottom),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                margin:
                                const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10)),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Cart',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              if (cart.cartItems.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => cart.clearCart(),
                                  icon: const Icon(Icons.delete_sweep,
                                      color: Colors.red),
                                  label: const Text('Clear All',
                                      style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: cart.cartItems.isEmpty
                              ? _buildEmptyCart()
                              : ListView.builder(
                            controller: scrollController,
                            itemCount: cart.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cart.cartItems[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  // FIX: Use the caching widget in the cart as well.
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CustomCachedImage(
                                      imageUrl: '${ApiConstants.baseUrl}${item.image}',
                                    ),
                                  ),
                                ),
                                title: Text(item.name),
                                subtitle: Text(
                                    'Rs. ${item.price.toStringAsFixed(2)}'),
                                trailing: SizedBox(
                                  width: 150,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.end,
                                    children: [
                                      QuantityToggle(itemId: item.id),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => cart
                                            .clearItemFromCart(item.id),
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

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty_cart.json', width: 150),
          const SizedBox(height: 16),
          const Text("Your cart is empty!",
              style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartFooter(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFf0f0f0), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Rs. ${cart.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
              _isPlacingOrder ? null : () => _placeOrder(context),
              child: _isPlacingOrder
                  ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
                  : const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {
    return Stack(
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
                    borderRadius: BorderRadius.circular(10)),
                constraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('${cart.cartItems.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search menu items...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildCongestionInfo() {
    if (_isCongestionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SizedBox(
            height: 40,
            child: Row(children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Loading congestion info...')
            ])),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCongestionStat('Congestion', _congestionLevel,
                color: levelColor),
            _buildCongestionStat('Queue', '$_queueCount'),
            _buildCongestionStat('Wait Time', '$_estimatedQueueTime min'),
          ],
        ),
      ),
    );
  }

  Widget _buildCongestionStat(String title, String value, {Color? color}) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ??
                    Theme.of(context).textTheme.bodyLarge?.color)),
      ],
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
            child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
          ),
          ...List.generate(
              2,
                  (index) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child:
                    Container(width: 120, height: 24, color: Colors.white),
                  ),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 160,
                          child: Card(
                            margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
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