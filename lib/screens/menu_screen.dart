import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cart_manager.dart';
import 'cart_screen.dart';
import 'food_detail_screen.dart';
import '../constants.dart';

class MenuScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final String? restaurantImage;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> _menuItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/menu-items/?restaurant=${widget.restaurantId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final items = jsonDecode(response.body);
        setState(() {
          _menuItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection Error. Could not reach server.";
        _isLoading = false;
      });
    }
  }

  String _getHeaderImage() {
    if (widget.restaurantImage != null && widget.restaurantImage!.isNotEmpty) {
      return widget.restaurantImage!;
    }
    return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000&auto=format&fit=crop";
  }

  String _getFoodImage(dynamic item) {
    if (item['image'] != null && item['image'].toString().isNotEmpty) {
      String path = item['image'].toString();
      return path.startsWith('http') ? path : '${ApiConstants.serverUrl}$path';
    }
    return "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400";
  }

  void _addToCartDirect(dynamic item) {
    CartManager.addItem(item);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item['name']} added!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey.shade50;
    final infoCardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.restaurantName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _getHeaderImage(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.orange.shade100,
                      child: const Icon(Icons.restaurant, size: 60, color: Colors.orange),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant info
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              color: infoCardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Authentic meals delivered to your doorstep.",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      Text(" 4.8", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 4),
                      Text("(200+ ratings)", style: TextStyle(color: subTextColor, fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text("Open", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Menu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        Text("${_menuItems.length} items", style: TextStyle(color: subTextColor, fontSize: 13)),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Food grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildFoodCard(_filteredItems[index], isDark, textColor),
                childCount: _filteredItems.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Cart FAB
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        ),
        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        label: Row(
          children: [
            const Text("View Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
              child: Text("${CartManager.getItems().length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(dynamic item, bool isDark, Color textColor) {
    final imageUrl = _getFoodImage(item);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodDetailScreen(item: item)),
        ).then((_) => setState(() {}));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.orange.shade50,
                        child: const Center(child: Icon(Icons.fastfood, color: Colors.orange, size: 40)),
                      ),
                    ),
                  ),
                  // Quick add button
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => _addToCartDirect(item),
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Food info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₵${item['price']}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(children: [
                        const Icon(Icons.star, size: 12, color: Colors.orange),
                        Text(" 4.8", style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                      ]),
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
}