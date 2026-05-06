import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import '../../state/app_state.dart';
import '../home/home_screen.dart';

class RoomCodeScreen extends StatefulWidget {
  final String roomCode;

  const RoomCodeScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<RoomCodeScreen> createState() => _RoomCodeScreenState();
}

class _RoomCodeScreenState extends State<RoomCodeScreen> {
  String get roomCode => widget.roomCode;

  final GlobalKey _downloadCardKey = GlobalKey();

  bool _copied = false;
  bool _sharing = false;
  bool _downloading = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: roomCode));

    if (!mounted) return;

    setState(() {
      _copied = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _copied = false;
    });
  }

  Future<void> _shareCode() async {
    if (_sharing) return;

    setState(() {
      _sharing = true;
    });

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Únete a mi sala de VOO con este código: $roomCode',
          subject: 'Código de sala VOO',
          title: 'Compartir código de sala',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el código'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
        });
      }
    }
  }

  Future<void> _downloadCodeCard() async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _downloadCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('No se encontró la tarjeta para descargar');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('No se pudo generar el PNG');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'codigo_sala_voo.png')
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo descargar el PNG'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  void _goHome() {
    context.read<AppState>().setUser(
      isHost: true,
      userName: context.read<AppState>().userName ?? 'Host',
      roomCode: roomCode,
      userId: context.read<AppState>().userId,
      salaId: context.read<AppState>().salaId,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        _copied ? const Color(0xFF22C55E) : const Color(0xFF9C4DFF);

    return Scaffold(
      backgroundColor: const Color(0xFF05051C),
      body: Stack(
        children: [
          Container(
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
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Código de Sala',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comparte el código o el QR con tus invitados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _copyCode,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A28),
                                Color(0xFF11111B),
                              ],
                            ),
                            border: Border.all(
                              color: accentColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 
                                  _copied ? 0.30 : 0.12,
                                ),
                                blurRadius: _copied ? 26 : 14,
                                spreadRadius: _copied ? 1.5 : 0.2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: QrImageView(
                                  data: roomCode,
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _copied ? 'Copiado ✔' : 'Tu código de sala',
                                style: TextStyle(
                                  color: _copied
                                      ? const Color(0xFF22C55E)
                                      : Colors.white70,
                                  fontSize: 15,
                                  fontWeight: _copied
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                roomCode,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _copied
                                    ? 'El código se ha copiado al portapapeles'
                                    : 'Toca el QR o el código para copiarlo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.56),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 138,
                            child: _ActionButton(
                              icon: _downloading
                                  ? Icons.hourglass_top
                                  : Icons.download_outlined,
                              color: const Color(0xFF9C4DFF),
                              onTap: _downloadCodeCard,
                            ),
                          ),
                          SizedBox(
                            width: 138,
                            child: _ActionButton(
                              icon: _sharing
                                  ? Icons.hourglass_top
                                  : Icons.share_outlined,
                              color: const Color(0xFF9C4DFF),
                              onTap: _shareCode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _MainButton(
                        label: 'Ir al inicio',
                        onTap: _goHome,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -10000,
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: RepaintBoundary(
                key: _downloadCardKey,
                child: Container(
                  width: 430,
                  padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.15,
                      colors: [
                        Color(0xFF171128),
                        Color(0xFF0C0A18),
                        Color(0xFF05051C),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 66,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
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
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: 'O',
                              style: TextStyle(
                                color: const Color(0xFFEAB308),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFEAB308)
                                        .withValues(alpha: 0.65),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: 'O',
                              style: TextStyle(
                                color: const Color(0xFFEF4444),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.65),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Código de Sala',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comparte esta tarjeta con tus invitados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1A1A28),
                              Color(0xFF11111B),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF9C4DFF),
                            width: 2.4,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: QrImageView(
                                data: roomCode,
                                version: QrVersions.auto,
                                size: 230,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tu código de acceso',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              roomCode,
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.color,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(widget.icon, color: widget.color, size: 20),
        ),
      ),
    );
  }
}

class _MainButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MainButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<_MainButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF22C55E);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}