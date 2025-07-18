import 'package:flutter/material.dart';
import 'package:food_app/widgets/custom_scaffold.dart';
import 'package:food_app/widgets/searchbar.dart';
import 'package:food_app/widgets/highlight.dart';
import 'package:food_app/customer_screens/budget.dart'; // Import the new MenuItem widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isMenuVisible = false;
  String _selectedMenu = 'Home'; // Track selected menu

  void toggleMenu() {
    setState(() {
      isMenuVisible = !isMenuVisible;
    });
  }

  void _selectMenu(String menuItem) {
    setState(() {
      _selectedMenu = menuItem;
      isMenuVisible = false; // Close the menu after selection
    });
    // Add navigation logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Top row: Menu + Notification
              Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 8.0,
                  right: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder:
                          (child, animation) => RotationTransition(
                            turns:
                                child.key == const ValueKey('menu')
                                    ? Tween<double>(
                                      begin: 0.75,
                                      end: 1,
                                    ).animate(animation)
                                    : Tween<double>(
                                      begin: 1,
                                      end: 0.75,
                                    ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child: IconButton(
                        key: ValueKey(isMenuVisible ? 'close' : 'menu'),
                        icon: Icon(
                          isMenuVisible ? Icons.close : Icons.menu,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: toggleMenu,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () {
                        print('Notifications tapped');
                      },
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: CustomSearchBar(
                  controller: searchController,
                  onChanged: (value) {
                    print('Searching for: $value');
                  },
                ),
              ),

              // Main content
              const Expanded(
                child: Center(
                  child: Text(
                    "Home Content Goes Here",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),

          // Custom side menu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: isMenuVisible ? 0 : -250,
            top: 0,
            bottom: 0,
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 150,
                    alignment: Alignment.center,
                    color: Colors.black,
                    child: const Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  MenuItem(
                    icon:
                        Icons.account_balance_wallet, // or any icon you prefer
                    title: 'Budget',
                    isSelected: _selectedMenu == 'Budget',
                    onTap: () {
                      _selectMenu('Budget');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetDashboard(),
                        ),
                      );
                    },
                  ),

                  MenuItem(
                    icon: Icons.person,
                    title: 'Profile',
                    isSelected: _selectedMenu == 'Profile',
                    onTap: () => _selectMenu('Profile'),
                  ),
                  MenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    isSelected: _selectedMenu == 'Settings',
                    onTap: () => _selectMenu('Settings'),
                  ),
                  MenuItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    isSelected: _selectedMenu == 'Notifications',
                    onTap: () => _selectMenu('Notifications'),
                  ),
                  const Divider(height: 1, thickness: 1),
                  MenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    isSelected: _selectedMenu == 'Logout',
                    onTap: () => _selectMenu('Logout'),
                  ),
                ],
              ),
            ),
          ),

          // Tap to close menu overlay
          if (isMenuVisible)
            Positioned.fill(
              left: 250,
              child: GestureDetector(
                onTap: toggleMenu,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
        ],
      ),
    );
  }
}
