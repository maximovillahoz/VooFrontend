import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'guest_status_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();

  bool _requestingLocation = false;

  bool get _isValid => _codeController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (!_isValid || _requestingLocation) return;

    LocationPermission permission = await Geolocator.checkPermission();

    // Si ya tiene permiso, no mostramos popup y pasa directo
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() {
        _requestingLocation = true;
      });

      try {
        final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activa la ubicación del dispositivo para continuar'),
            ),
          );
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (!mounted) return;

        context.read<AppState>().setGuestJoinData(
              roomCode: _codeController.text.trim().toUpperCase(),
              latitud: position.latitude,
              longitud: position.longitude,
              accuracy: position.accuracy,
            );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GuestStatusScreen(),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _requestingLocation = false;
          });
        }
      }
      return;
    }

    // Si no tiene permiso, mostramos popup propio
    final bool? wantsToContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LocationPermissionDialog(),
    );

    if (wantsToContinue != true) return;

    setState(() {
      _requestingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa la ubicación del dispositivo para continuar'),
          ),
        );
        return;
      }

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes permitir la ubicación para entrar a la sala'),
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La ubicación está bloqueada. Actívala desde ajustes para continuar',
            ),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      context.read<AppState>().setGuestJoinData(
            roomCode: _codeController.text.trim().toUpperCase(),
            latitud: position.latitude,
            longitud: position.longitude,
            accuracy: position.accuracy,
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GuestStatusScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestingLocation = false;
        });
      }
    }
  }

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
              child: SingleChildScrollView(
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
                    const SizedBox(height: 20),
                    const Text(
                      'Tu sala',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 46,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                        children: [
                          TextSpan(
                            text: 'V',
                            style: TextStyle(
                              color: const Color(0xFF22C55E),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.65),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'o',
                            style: TextStyle(
                              color: const Color(0xFFEAB308),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFEAB308)
                                      .withValues(alpha: 0.65),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'o',
                            style: TextStyle(
                              color: const Color(0xFFEF4444),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.65),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: '!',
                            style: TextStyle(
                              color: const Color(0xFF9C4DFF),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF9C4DFF)
                                      .withValues(alpha: 0.65),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Introduce el código para unirte a la sala.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _VooInput(
                      controller: _codeController,
                      hintText: 'Código de Sala',
                    ),
                    const SizedBox(height: 12),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: _isValid ? 0 : 1,
                      child: const Text(
                        'Escribe el código para continuar.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NextButton(
                          enabled: _isValid && !_requestingLocation,
                          loading: _requestingLocation,
                          onTap: _goNext,
                        ),
                      ],
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

class _VooInput extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;

  const _VooInput({
    required this.hintText,
    required this.controller,
  });

  @override
  State<_VooInput> createState() => _VooInputState();
}

class _VooInputState extends State<_VooInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF9C4DFF).withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 15,
            ),
            filled: true,
            fillColor: const Color(0xFF151525),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: const Color(0xFF9C4DFF).withValues(alpha: 0.38),
                width: 1.6,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: Color(0xFF9C4DFF),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _RoundBackButton({
    required this.onTap,
  });

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
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;

  const _NextButton({
    required this.onTap,
    required this.enabled,
    required this.loading,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? const Color(0xFF22C55E)
        : Colors.grey;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.enabled && !widget.loading) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.enabled && !widget.loading) {
          setState(() => _pressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: (_pressed && widget.enabled)
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: widget.loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFF22C55E),
                ),
              )
            : Text(
                'Siguiente',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _LocationPermissionDialog extends StatelessWidget {
  const _LocationPermissionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A28),
              Color(0xFF11111B),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF9C4DFF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C4DFF).withValues(alpha: 0.18),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 42,
              color: Colors.white,
            ),
            const SizedBox(height: 18),
            const Text(
              'Necesitamos tu ubicación para poder entrar a la sala.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Solo la usamos para comprobar que estás dentro del radio del evento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DialogButton(
                  label: 'Denegar',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context, false);
                  },
                ),
                const SizedBox(width: 14),
                _DialogButton(
                  label: 'Permitir',
                  color: const Color(0xFF22C55E),
                  onTap: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.color,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
