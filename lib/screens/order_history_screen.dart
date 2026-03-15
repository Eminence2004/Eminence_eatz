import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'tracking_screen.dart';
import '../constants.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = ApiConstants.baseUrl;
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      String? token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$baseUrl/orders/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _orders = jsonDecode(response.body);
          _orders = _orders.reversed.toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'PREPARING': return Colors.blue;
      case 'DELIVERING': return Colors.purple;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Icons.hourglass_empty;
      case 'PREPARING': return Icons.restaurant;
      case 'DELIVERING': return Icons.delivery_dining;
      case 'COMPLETED': return Icons.check_circle;
      case 'CANCELLED': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey.shade50;
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("My Orders", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _orders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No orders yet", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index], isDark),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isDark) {
    final String status = order['status'] ?? 'PENDING';
    final Color color = _getStatusColor(status);
    final String date = order['created_at'] != null ? order['created_at'].toString().substring(0, 10) : 'Recent';
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Order #${order['id']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              Text(date, style: TextStyle(color: subTextColor, fontSize: 12)),
            ],
          ),
          Divider(height: 24, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(_getStatusIcon(status), color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Estimated delivery: 30-45 min", style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
              const Spacer(),
              Text("₵${order['total_price']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.map, size: 18),
              label: const Text("Track Live Delivery"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackingScreen(orderId: order['id']))),
            ),
          ),
        ],
      ),
    );
  }
}