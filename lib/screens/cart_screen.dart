import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cart_manager.dart';
import 'login_screen.dart';
import '../constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _storage = const FlutterSecureStorage();
  final _addressController = TextEditingController();
  final String baseUrl = ApiConstants.baseUrl;
  bool _isLoading = false;

  Future<void> _processCheckout() async {
    if (_addressController.text.isEmpty) {
      _showErrorSnack("Please enter a delivery address!");
      return;
    }
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      _showLoginPrompt();
      return;
    }
    _placeOrder(token);
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Text(msg),
        ]),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Login Required", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Your session may have expired. Please sign in to continue."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Login", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(String token) async {
    setState(() => _isLoading = true);
    try {
      final cartItems = CartManager.getItems();
      if (cartItems.isEmpty) { setState(() => _isLoading = false); return; }
      int restaurantId = cartItems[0]['restaurant'];
      List<int> itemIds = cartItems.map((item) => item['id'] as int).toList();
      final orderResponse = await http.post(
        Uri.parse('$baseUrl/orders/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'items': itemIds, 'total_price': CartManager.getTotal(), 'restaurant': restaurantId, 'delivery_address': _addressController.text}),
      );
      if (orderResponse.statusCode == 201 || orderResponse.statusCode == 200) {
        final orderData = jsonDecode(orderResponse.body);
        await _initiatePayment(orderData['id'], token);
      } else if (orderResponse.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        _showLoginPrompt();
        throw "Session expired. Please log in again.";
      } else {
        throw "Failed to create order. Error: ${orderResponse.statusCode}";
      }
    } catch (e) {
      if (mounted) _showErrorSnack(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiatePayment(int orderId, String token) async {
    try {
      final payResponse = await http.post(
        Uri.parse('$baseUrl/pay/$orderId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (payResponse.statusCode == 200) {
        final data = jsonDecode(payResponse.body);
        final Uri url = Uri.parse(data['authorization_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          CartManager.clearCart();
          if (mounted) Navigator.pop(context);
        } else throw 'Could not launch payment browser';
      } else {
        final errorMsg = jsonDecode(payResponse.body)['error'] ?? 'Payment Init Failed';
        throw errorMsg;
      }
    } catch (e) {
      if (mounted) _showErrorSnack("Payment Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = CartManager.getItems();
    final double subtotal = CartManager.getTotal();
    const double deliveryFee = 15.00;
    final double total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => CartManager.clearCart()),
              child: const Text("Clear", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: items.isEmpty ? _buildEmptyCart(isDark) : _buildCartBody(items, subtotal, deliveryFee, total, isDark),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
            child: const Text("🛒", style: TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 24),
          Text("Your cart is empty", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text("Add items from a restaurant to get started", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCartBody(List<Map<String, dynamic>> items, double subtotal, double deliveryFee, double total, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...items.asMap().entries.map((entry) => _buildCartItem(entry.value, entry.key, isDark)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Enter your delivery address",
                        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 16),
                    _summaryRow("Subtotal", "₵${subtotal.toStringAsFixed(2)}", subTextColor, textColor),
                    const SizedBox(height: 10),
                    _summaryRow("Delivery Fee", "₵${deliveryFee.toStringAsFixed(2)}", subTextColor, textColor),
                    const SizedBox(height: 10),
                    Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                        Text("₵${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processCheckout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text("₵${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, bool isDark) {
    final String imageUrl = (item['image'] != null && item['image'].toString().isNotEmpty) ? item['image'].toString() : '';
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 65, height: 65, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _foodPlaceholder())
                : _foodPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("₵${item['price']}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => CartManager.removeItem(index)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodPlaceholder() {
    return Container(
      width: 65, height: 65,
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.fastfood, color: Colors.orange, size: 28),
    );
  }

  Widget _summaryRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor)),
      ],
    );
  }
}