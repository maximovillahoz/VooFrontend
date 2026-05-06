import 'package:flutter/material.dart';
import 'dart:async';

class SentRequestDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const SentRequestDialog({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<SentRequestDialog> createState() => _SentRequestDialogState();
}

class _SentRequestDialogState extends State<SentRequestDialog> {
  Timer? _timer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(milliseconds: 1350), () {
      if (!mounted || _closed) return;

      _closed = true;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A28),
                Color(0xFF11111B),
                Color(0xFF090912),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF9C4DFF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B3DFF).withValues(alpha: 0.28),
                blurRadius: 28,
                spreadRadius: 1.2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B1452),
                      Color(0xFF7E2BE8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C4DFF).withValues(alpha: 0.36),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}