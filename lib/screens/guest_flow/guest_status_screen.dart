import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../shared_flow/questions_screen.dart';

class GuestStatusScreen extends StatefulWidget {
  const GuestStatusScreen({super.key});

  @override
  State<GuestStatusScreen> createState() => _GuestStatusScreenState();
}

class _GuestStatusScreenState extends State<GuestStatusScreen> {
  String? selectedStatus;

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
              Color(0xFF171128),
              Color(0xFF0C0A18),
              Color(0xFF05051C),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _RoundBackButton(
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Escoge tu estado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona cómo quieres aparecer dentro de la sala.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusOption(
                          color: const Color(0xFF22C55E),
                          label: 'Soltero',
                          subtitle: 'Abierto a conocer a alguien',
                          isSelected: selectedStatus == 'soltero',
                          onTap: () {
                            setState(() {
                              selectedStatus = 'soltero';
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _StatusOption(
                          color: const Color(0xFFEAB308),
                          label: 'Haciendo amigos',
                          subtitle: 'Buscando buen rollo y conectar',
                          isSelected: selectedStatus == 'amigos',
                          onTap: () {
                            setState(() {
                              selectedStatus = 'amigos';
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _StatusOption(
                          color: const Color(0xFFEF4444),
                          label: 'En pareja',
                          subtitle: 'Aquí para disfrutar y socializar',
                          isSelected: selectedStatus == 'pareja',
                          onTap: () {
                            setState(() {
                              selectedStatus = 'pareja';
                            });
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _NextButton(
                        enabled: selectedStatus != null,
                        onTap: () {
                          if (selectedStatus == null) return;

                          context.read<AppState>().setStatusData(selectedStatus!);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionsScreen(
                                estado: selectedStatus!,
                                isGuestFlow: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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

class _StatusOption extends StatefulWidget {
  final Color color;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.color,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatusOption> createState() => _StatusOptionState();
}

class _StatusOptionState extends State<_StatusOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _pressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: active
                ? [
                    widget.color.withValues(alpha: 0.25),
                    widget.color.withValues(alpha: 0.10),
                  ]
                : const [
                    Color(0xFF1A1A28),
                    Color(0xFF11111B),
                  ],
          ),
          border: Border.all(
            color: active ? widget.color : widget.color.withValues(alpha: 0.3),
            width: active ? 2.5 : 1.4,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? widget.color : widget.color.withValues(alpha: 0.2),
              ),
              child: Icon(
                _getIcon(),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: widget.color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.label) {
      case 'Soltero':
        return Icons.favorite_border;
      case 'Haciendo amigos':
        return Icons.groups;
      case 'En pareja':
        return Icons.favorite;
      default:
        return Icons.circle;
    }
  }
}

class _RoundBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _RoundBackButton({required this.onTap});

  @override
  State<_RoundBackButton> createState() => _RoundBackButtonState();
}

class _RoundBackButtonState extends State<_RoundBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3B1452),
              Color(0xFF24103A),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF7E2BE8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B3DFF).withValues(alpha: _pressed ? 0.5 : 0.2),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _NextButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? const Color(0xFF22C55E) : Colors.grey;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.enabled) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.enabled) {
          setState(() => _pressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color, width: 2),
          color: Colors.transparent,
          boxShadow: _pressed && widget.enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          'Siguiente',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
