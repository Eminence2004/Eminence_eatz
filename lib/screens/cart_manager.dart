// File: lib/cart_manager.dart
class CartManager {
  static final List<Map<String, dynamic>> _items = [];

  static void addItem(Map<String, dynamic> item) {
    _items.add(item);
  }

  // NEW: Remove item at a specific position
  static void removeItem(int index) {
    _items.removeAt(index);
  }

  static List<Map<String, dynamic>> getItems() {
    return _items;
  }

  static void clearCart() {
    _items.clear();
  }

  static double getTotal() {
    double total = 0;
    for (var item in _items) {
      total += double.parse(item['price'].toString());
    }
    return total;
  }
}