// frontend/lib/screens/designs/laser_scanner_widget.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class LaserScannerWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final List<String> scanningTexts;
  
  const LaserScannerWidget({
    super.key,
    required this.imageBytes,
    required this.scanningTexts,
  });

  @override
  State<LaserScannerWidget> createState() => _LaserScannerWidgetState();
}

class _LaserScannerWidgetState extends State<LaserScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentTextIndex = 0;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
    
    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % widget.scanningTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.memory(
                widget.imageBytes,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  top: _animation.value * 260,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.scanningTexts[_currentTextIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
      ],
    );
  }
}
