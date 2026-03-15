import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const PhoneScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  String _formatPhone(String phone) {
    phone = phone.trim();
    if (phone.startsWith('0')) phone = '+233' + phone.substring(1);
    if (!phone.startsWith('+')) phone = '+233$phone';
    return phone;
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final phone = _formatPhone(_phoneController.text);

    try {
      // 1. Register the user with phone
      final registerRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': widget.fullName,
          'email': widget.email,
          'password': widget.password,
          'phone': phone,
        }),
      );

      if (registerRes.statusCode != 201) {
        final error = jsonDecode(registerRes.body);
        throw error['error'] ?? 'Registration failed';
      }

      // 2. Send OTP
      final otpRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/send-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (otpRes.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phone: phone,
                isLogin: false,
              ),
            ),
          );
        }
      } else {
        final error = jsonDecode(otpRes.body);
        throw error['error'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: Colors.black),
              ),
              const SizedBox(height: 30),

              const Text(
                "Your Phone\nNumber 📱",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll send a verification code to confirm it's you",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 50),

              // Phone input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '024 123 4567',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: const Text(
                      '🇬🇭 +233',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Standard SMS rates may apply",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "SEND CODE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}