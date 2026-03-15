import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  String _formatPhone(String phone) {
    phone = phone.trim();
    if (phone.startsWith('0')) phone = '+233' + phone.substring(1);
    if (!phone.startsWith('+')) phone = '+233$phone';
    return phone;
  }

  Future<void> _sendLoginOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final phone = _formatPhone(_phoneController.text);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (response.statusCode == 200) {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen(phone: phone, isLogin: true)));
      } else {
        final error = jsonDecode(response.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['error'] ?? 'Account not found'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
                ),
              ),
              const SizedBox(height: 30),
              Text("Welcome\nBack! 👋", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.2, color: textColor)),
              const SizedBox(height: 8),
              Text("Enter your phone number to sign in", style: TextStyle(fontSize: 15, color: subTextColor)),
              const SizedBox(height: 50),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                decoration: InputDecoration(
                  hintText: '024 123 4567',
                  hintStyle: TextStyle(color: subTextColor, fontWeight: FontWeight.normal),
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: const Text('🇬🇭 +233', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                  filled: true,
                  fillColor: fillColor,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendLoginOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SEND CODE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: subTextColor)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    child: const Text("Sign Up", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}