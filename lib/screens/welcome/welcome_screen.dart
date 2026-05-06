import 'package:flutter/material.dart';
import '../host_flow/register_host_screen.dart';
import '../guest_flow/register_guest_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051C),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.25,
            colors: [
              Color(0xFF130F22),
              Color(0xFF0A0917),
              Color(0xFF05051C),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                child: Column(
                  children: [
                    const Spacer(),
                    Text(
                      'Bienvenido',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _BigGlowingVooTitle(),
                    const SizedBox(height: 56),
                    _WelcomeActionButton(
                      title: 'Crear sala',
                      icon: Icons.add,
                      color: const Color(0xFF63B3FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterHostScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _WelcomeActionButton(
                      title: 'Entrar a la sala',
                      icon: Icons.qr_code_2_rounded,
                      color: const Color(0xFF9C4DFF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterGuestScreen(),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigGlowingVooTitle extends StatelessWidget {
  const _BigGlowingVooTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _VooLetter(
          letter: 'V',
          color: Color(0xFF22C55E),
        ),
        SizedBox(width: 8),
        _VooLetter(
          letter: 'O',
          color: Color(0xFFEAB308),
        ),
        SizedBox(width: 8),
        _VooLetter(
          letter: 'O',
          color: Color(0xFFEF4444),
        ),
      ],
    );
  }
}

class _VooLetter extends StatelessWidget {
  final String letter;
  final Color color;

  const _VooLetter({
    required this.letter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w900,
        color: color,
        height: 0.92,
        letterSpacing: 1.0,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.95),
            blurRadius: 10,
          ),
          Shadow(
            color: color.withValues(alpha: 0.65),
            blurRadius: 24,
          ),
          Shadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 42,
          ),
        ],
      ),
    );
  }
}

class _WelcomeActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WelcomeActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_WelcomeActionButton> createState() => _WelcomeActionButtonState();
}

class _WelcomeActionButtonState extends State<_WelcomeActionButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkButton = Color(0xFF17172A);
    const darkButton2 = Color(0xFF202036);

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final pulse = _glowController.value;
        final glowOpacity = _pressed ? 0.36 : 0.14 + (pulse * 0.08);
        final borderOpacity = _pressed ? 0.95 : 0.42 + (pulse * 0.16);
        final scale = _pressed ? 0.975 : 1.0;

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(30),
              splashColor: widget.color.withValues(alpha: 0.10),
              highlightColor: widget.color.withValues(alpha: 0.05),
              onHighlightChanged: (value) {
                if (mounted) {
                  setState(() {
                    _pressed = value;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      darkButton2,
                      darkButton,
                    ],
                  ),
                  border: Border.all(
                    color: widget.color.withValues(alpha: borderOpacity),
                    width: _pressed ? 2.4 : 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: glowOpacity),
                      blurRadius: _pressed ? 28 : 18 + (pulse * 10),
                      spreadRadius: _pressed ? 1.6 : 0.3 + (pulse * 0.8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 
                            _pressed ? 0.90 : 0.46,
                          ),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 
                              _pressed ? 0.24 : 0.10,
                            ),
                            blurRadius: _pressed ? 18 : 10,
                            spreadRadius: _pressed ? 1.2 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.75),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}