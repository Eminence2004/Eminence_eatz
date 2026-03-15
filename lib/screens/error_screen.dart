import 'package:flutter/material.dart';

class ErrorScreen extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final ErrorType type;

  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.type = ErrorType.connection,
  });

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

enum ErrorType { connection, server, notFound }

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;
  late Animation<double> _fadeAnim;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case ErrorType.connection:
        return Icons.wifi_off_rounded;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      case ErrorType.notFound:
        return Icons.search_off_rounded;
    }
  }

  Color get _color {
    switch (widget.type) {
      case ErrorType.connection:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.blue;
    }
  }

  String get _emoji {
    switch (widget.type) {
      case ErrorType.connection:
        return "📡";
      case ErrorType.server:
        return "🌩️";
      case ErrorType.notFound:
        return "🔍";
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onRetry();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _bounceAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnim.value),
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_emoji, style: const TextStyle(fontSize: 52)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Animated dots below icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final delay = i * 0.3;
                    final opacity = (((_controller.value + delay) % 1.0)).clamp(0.2, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // Retry button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isRetrying ? null : _handleRetry,
                icon: _isRetrying
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  _isRetrying ? "Retrying..." : "Try Again",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}