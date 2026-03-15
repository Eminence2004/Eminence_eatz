import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _imageUrl = "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=1000&auto=format&fit=crop";
  String _title = "Eminence\nEatz";
  String _subtitle = "Order your favorite meals from top restaurants in Ghana. Fast delivery to your doorstep.";
  String _promoText = "FREE DELIVERY";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/app-config/'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['welcome_image'] != null && data['welcome_image'].toString().isNotEmpty) {
            _imageUrl = data['welcome_image'].toString();
          }
          if (data['welcome_title'] != null && data['welcome_title'].toString().isNotEmpty) {
            _title = data['welcome_title'].toString().replaceAll(' ', '\n');
          }
          if (data['welcome_subtitle'] != null && data['welcome_subtitle'].toString().isNotEmpty) {
            _subtitle = data['welcome_subtitle'].toString();
          }
          if (data['promo_text'] != null && data['promo_text'].toString().isNotEmpty) {
            _promoText = data['promo_text'].toString();
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Silently fall back to defaults
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background image
          Positioned.fill(
            child: _isLoading
                ? Container(color: Colors.deepOrange.shade900)
                : Image.network(
              _imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.deepOrange.shade900);
              },
            ),
          ),

          // 2. Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Loading shimmer overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
            ),

          // 4. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Logo badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    _subtitle,
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 12),

                  // Promo + trust badges
                  Row(
                    children: [
                      _badge("🎉 $_promoText"),
                      const SizedBox(width: 10),
                      _badge("⭐ Top Restaurants"),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}