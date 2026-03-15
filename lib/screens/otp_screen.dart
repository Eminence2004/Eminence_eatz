import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinput/pinput.dart';
import '../constants.dart';
import 'restaurant_list_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final bool isLogin;
  const OtpScreen({super.key, required this.phone, required this.isLogin});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _storage = const FlutterSecureStorage();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  Future<void> _verifyOtp(String pin) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': widget.phone, 'otp': pin}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] != null) await _storage.write(key: 'access_token', value: data['access']);
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RestaurantListScreen()), (route) => false);
        }
      } else {
        final error = jsonDecode(response.body);
        setState(() { _errorMessage = error['error'] ?? 'Invalid OTP. Please try again.'; });
        _pinController.clear();
      }
    } catch (e) {
      setState(() { _errorMessage = 'Connection error. Please try again.'; });
      _pinController.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() { _isResending = true; _errorMessage = null; });
    final endpoint = widget.isLogin ? '/login-otp/' : '/send-otp/';
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': widget.phone}),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('New code sent successfully!')]),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          setState(() => _errorMessage = 'Failed to resend code. Try again.');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final pinBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50;
    final pinBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final backBtnColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

    final defaultPinTheme = PinTheme(
      width: 56, height: 60,
      textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
      decoration: BoxDecoration(
        color: pinBgColor,
        border: Border.all(color: pinBorderColor, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: backBtnColor, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: const Text("📱", style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 24),
              Text("Enter\nVerification Code", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2, color: textColor)),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  text: "We sent a 6-digit code to\n",
                  style: TextStyle(fontSize: 15, color: subTextColor),
                  children: [TextSpan(text: widget.phone, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.orange.shade50,
                  ),
                  submittedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.orange.shade50,
                  ),
                  errorPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: Colors.red.shade300, width: 1.5),
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onCompleted: (pin) => _verifyOtp(pin),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _errorMessage != null
                    ? Container(
                  key: const ValueKey('error'),
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w500))),
                  ]),
                )
                    : const SizedBox(key: ValueKey('no-error')),
              ),
              const SizedBox(height: 24),
              if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.orange)),
              const SizedBox(height: 16),
              Center(
                child: _isResending
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : TextButton(
                  onPressed: _resendOtp,
                  child: RichText(
                    text: TextSpan(
                      text: "Didn't receive the code? ",
                      style: TextStyle(color: subTextColor, fontSize: 14),
                      children: const [TextSpan(text: "Resend", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}