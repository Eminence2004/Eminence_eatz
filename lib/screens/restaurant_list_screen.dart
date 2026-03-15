import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';
import 'order_history_screen.dart';
import 'welcome_screen.dart';
import 'cart_manager.dart';
import 'error_screen.dart';
import '../constants.dart';
import '../theme_provider.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = ApiConstants.baseUrl;

  List<dynamic> _restaurants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants({bool retry = true}) async {
    try {
      String? token = await _storage.read(key: 'access_token');
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _restaurants = jsonDecode(response.body);
          _isLoading = false;
          _error = null;
        });
      } else if (response.statusCode == 401 && retry) {
        await _storage.delete(key: 'access_token');
        _fetchRestaurants(retry: false);
      } else {
        setState(() {
          _error = 'Server Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection Error. Could not reach server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      await _storage.deleteAll();
      CartManager.clearCart();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
        );
      }
    }
  }

  String _getRestaurantImage(Map<String, dynamic> restaurant) {
    if (restaurant['image'] != null && restaurant['image'].toString().isNotEmpty) {
      return restaurant['image'].toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _error != null
            ? ErrorScreen(
          title: "Oops! No Connection",
          message: "Could not reach the server.\nCheck your internet and try again.",
          type: ErrorType.connection,
          onRetry: () {
            setState(() => _isLoading = true);
            _fetchRestaurants();
          },
        )
            : _buildBody(isDark, themeProvider),
      ),
    );
  }

  Widget _buildBody(bool isDark, ThemeProvider themeProvider) {
    return RefreshIndicator(
      onRefresh: _fetchRestaurants,
      color: Colors.orange,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "Delivering to",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Current Location",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // History button
                      _iconButton(
                        icon: Icons.history_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrderHistoryScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dark/Light mode toggle
                      _iconButton(
                        icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Colors.orange,
                        onTap: () => themeProvider.toggleTheme(),
                      ),
                      const SizedBox(width: 8),
                      // Logout button
                      _iconButton(
                        icon: Icons.logout_rounded,
                        color: Colors.red,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Promo banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF5500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "FREE DELIVERY",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Order your\nfavorite meal!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Fast delivery to your doorstep",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Text("🍔", style: TextStyle(fontSize: 60)),
                ],
              ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Restaurants Near You",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "${_restaurants.length} available",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRestaurantCard(_restaurants[index], isDark),
                childCount: _restaurants.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant, bool isDark) {
    final imageUrl = _getRestaurantImage(restaurant);

    return GestureDetector(
      onTap: () {
        if (restaurant['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                restaurantId: restaurant['id'],
                restaurantName: restaurant['name'] ?? 'Menu',
                restaurantImage: imageUrl.isNotEmpty ? imageUrl : null,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderImage(),
              )
                  : _placeholderImage(),
            ),

            // Restaurant info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        restaurant['name'] ?? 'Restaurant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.orange),
                            SizedBox(width: 3),
                            Text("4.8",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        restaurant['location'] ?? 'No location info',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "25-35 min",
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.orange.shade50,
      child: const Center(
        child: Icon(Icons.restaurant, size: 50, color: Colors.orange),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}