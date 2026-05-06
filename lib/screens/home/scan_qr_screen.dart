import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _torchEnabled = false;
  bool _handledResult = false;
  String _statusText = 'Apunta al QR dentro del recuadro';

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handledResult) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    if (!rawValue.startsWith('voo-profile:')) {
      setState(() {
        _statusText = 'Este QR no es válido para Voo';
      });
      return;
    }

    final usuarioId = rawValue.replaceFirst('voo-profile:', '').trim();

    if (usuarioId.isEmpty) {
      setState(() {
        _statusText = 'QR de perfil inválido';
      });
      return;
    }

    _handledResult = true;

    try {
      setState(() {
        _statusText = 'Perfil detectado, cargando datos...';
      });

      final usuario = await ApiService.getUsuarioPorId(usuarioId);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ScanResultDialog(
          usuario: usuario,
          qrValue: rawValue,
          onClose: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onScanAgain: () {
            Navigator.pop(context);
            setState(() {
              _handledResult = false;
              _statusText = 'Apunta al QR dentro del recuadro';
            });
          },
          onConfirm: () async {
            final myId = context.read<AppState>().userId;

            if (myId == null || myId.isEmpty) return;

            final resultado = await ApiService.completarRetoActual(
              usuarioId: myId,
              usuarioEscaneadoId: usuario.id,
            );

            if (!context.mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resultado['mensaje']?.toString() ?? 'Reto procesado'),
              ),
            );

            setState(() {
              _handledResult = false;
              _statusText = 'Apunta al QR dentro del recuadro';
            });
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _handledResult = false;
        _statusText = 'No se pudo cargar el perfil escaneado';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando perfil: $e'),
        ),
      );
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051C),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                _onDetect(capture);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _BackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _SquareActionButton(
                        icon: _torchEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: _toggleTorch,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Escanear QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF9C4DFF),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C4DFF).withValues(alpha: 0.35),
                          blurRadius: 26,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        _CornerAlign(alignment: Alignment.topLeft),
                        _CornerAlign(alignment: Alignment.topRight),
                        _CornerAlign(alignment: Alignment.bottomLeft),
                        _CornerAlign(alignment: Alignment.bottomRight),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF9C4DFF).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: const Text(
                      'Escanea el QR de otro perfil para completar retos y dinámicas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerAlign extends StatelessWidget {
  final Alignment alignment;

  const _CornerAlign({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(16)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(16)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(16)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(16)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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

class _SquareActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SquareActionButton> createState() => _SquareActionButtonState();
}

class _SquareActionButtonState extends State<_SquareActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF9C4DFF);

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
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: Icon(
          widget.icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}

class _ScanResultDialog extends StatelessWidget {
  final SalaUsuarioModel usuario;
  final String qrValue;
  final VoidCallback onClose;
  final VoidCallback onScanAgain;
  final VoidCallback onConfirm;

  const _ScanResultDialog({
    required this.usuario,
    required this.qrValue,
    required this.onClose,
    required this.onScanAgain,
    required this.onConfirm,
  });

  Color _statusColor(String status) {
    final value = status.toLowerCase().trim();

    if (value.contains('soltero')) {
      return const Color(0xFF22C55E);
    }

    if (value.contains('amigos') || value.contains('amigo')) {
      return const Color(0xFFEAB308);
    }

    if (value.contains('pareja')) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF9C4DFF);
  }

  ImageProvider? _profileImage(String? foto) {
    if (foto == null || foto.trim().isEmpty) return null;

    try {
      var cleanBase64 = foto.trim();

      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      return MemoryImage(base64Decode(cleanBase64));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectedName = usuario.nombre;
    final detectedAge = usuario.edad;
    final detectedStatus = usuario.estado;
    final detectedPoints = usuario.puntos;

    final statusColor = _statusColor(detectedStatus);
    final image = _profileImage(usuario.foto);

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
              Icons.qr_code_2_rounded,
              size: 42,
              color: Colors.white,
            ),
            const SizedBox(height: 18),
            const Text(
              'Perfil detectado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF151525),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF9C4DFF).withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(2.4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor,
                        width: 2.4,
                      ),
                    ),
                    child: ClipOval(
                      child: image != null
                          ? Image(
                              image: image,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : Container(
                              color: const Color(0xFF101018),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$detectedName, $detectedAge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: $detectedStatus',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Puntos: $detectedPoints',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DialogButton(
                  label: 'Otra vez',
                  color: const Color(0xFFEF4444),
                  onTap: onScanAgain,
                ),
                const SizedBox(width: 14),
                _DialogButton(
                  label: 'Confirmar reto',
                  color: const Color(0xFF22C55E),
                  onTap: onConfirm,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onClose,
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                    color: widget.color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}