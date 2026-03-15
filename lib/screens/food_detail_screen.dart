import 'package:flutter/material.dart';
import 'cart_manager.dart';

class FoodDetailScreen extends StatefulWidget {
  final dynamic item;
  const FoodDetailScreen({super.key, required this.item});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;

  void _addToCart() {
    for (int i = 0; i < _quantity; i++) {
      CartManager.addItem(widget.item);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.item['name']} x$_quantity added to cart!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        duration: const Duration(milliseconds: 1000),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final item = widget.item;
    final String imageUrl = (item['image'] != null && item['image'].toString().isNotEmpty)
        ? item['image'].toString()
        : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400";
    final String description = (item['description'] != null && item['description'].toString().isNotEmpty)
        ? item['description'].toString()
        : "A delicious meal prepared fresh and delivered to your doorstep.";

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 320,
                        width: double.infinity,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 320,
                            color: Colors.orange.shade50,
                            child: const Icon(Icons.fastfood, size: 80, color: Colors.orange),
                          ),
                        ),
                      ),
                      Container(
                        height: 320,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black26, Colors.transparent],
                            stops: [0.0, 0.4],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                              ),
                              child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(item['name'], style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
                            ),
                            Text("₵${item['price']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statChip(Icons.star, "4.8", Colors.orange),
                            const SizedBox(width: 12),
                            _statChip(Icons.access_time, "25-35 min", Colors.blue),
                            const SizedBox(width: 12),
                            _statChip(Icons.local_fire_department, "~350 kcal", Colors.red),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 8),
                        Text(description, style: TextStyle(fontSize: 15, color: subTextColor, height: 1.6)),
                        const SizedBox(height: 24),
                        Text("Quantity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _quantityButton(icon: Icons.remove, onTap: () { if (_quantity > 1) setState(() => _quantity--); }, isDark: isDark),
                            const SizedBox(width: 20),
                            Text("$_quantity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(width: 20),
                            _quantityButton(icon: Icons.add, onTap: () => setState(() => _quantity++), filled: true, isDark: isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total amount", style: TextStyle(color: subTextColor, fontSize: 13)),
                    Text(
                      "₵${(double.parse(item['price'].toString()) * _quantity).toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("Add to Cart 🛒", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onTap, bool filled = false, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: filled ? Colors.orange : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: filled ? Colors.white : (isDark ? Colors.white : Colors.black), size: 20),
      ),
    );
  }
}