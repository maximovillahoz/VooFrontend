import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'loading_screen.dart';

class CameraScreen extends StatefulWidget {
  final Widget nextScreen;

  const CameraScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late final FaceDetector _faceDetector;

  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;
  bool _isProcessingFace = false;
  bool _flashEnabled = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  String _faceStatus = 'Buscando cara...';
  bool _faceDetected = false;
  bool _faceCentered = false;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    if (kIsWeb) {
      setState(() {
        _isInitializing = false;
        _faceStatus = 'Esta pantalla con detección facial es solo para móvil.';
      });
      return;
    }

    try {
      setState(() {
        _isInitializing = true;
      });

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No hay cámaras disponibles');
      }

      if (_cameras.length > 1 && cameraIndex == 0) {
        final frontIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (frontIndex != -1) {
          cameraIndex = frontIndex;
        }
      }

      _currentCameraIndex = cameraIndex.clamp(0, _cameras.length - 1);

      await _controller?.dispose();

      final controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = _minZoom.clamp(1.0, _maxZoom);
      await controller.setZoomLevel(_currentZoom);
      await controller.setFlashMode(FlashMode.off);

      await controller.startImageStream(_processCameraImage);

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitializing = false;
        _flashEnabled = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _faceStatus = 'No se pudo abrir la cámara.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la cámara'),
        ),
      );
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFace) return;
    if (!mounted) return;
    if (_controller == null) return;

    _isProcessingFace = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final camera = _cameras[_currentCameraIndex];
      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

      final format = InputImageFormatValue.fromRawValue(image.format.raw);

      if (rotation == null || format == null) {
        _isProcessingFace = false;
        return;
      }

      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) {
        _isProcessingFace = false;
        return;
      }

      if (faces.isEmpty) {
        setState(() {
          _faceDetected = false;
          _faceCentered = false;
          _faceStatus = 'No se detecta ninguna cara';
        });
        _isProcessingFace = false;
        return;
      }

      final face = faces.first;

      final frameWidth = image.width.toDouble();
      final frameHeight = image.height.toDouble();

      final faceCenterX = face.boundingBox.left + (face.boundingBox.width / 2);
      final faceCenterY = face.boundingBox.top + (face.boundingBox.height / 2);

      final targetCenterX = frameWidth / 2;
      final targetCenterY = frameHeight / 2;

      final dx = (faceCenterX - targetCenterX).abs();
      final dy = (faceCenterY - targetCenterY).abs();

      final centered = dx < frameWidth * 0.15 && dy < frameHeight * 0.15;

      setState(() {
        _faceDetected = true;
        _faceCentered = centered;
        _faceStatus = centered
            ? 'Cara detectada y centrada'
            : 'Mueve tu cara al centro';
      });
    } catch (_) {
    } finally {
      _isProcessingFace = false;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isSwitchingCamera) return;

    _isSwitchingCamera = true;

    try {
      await _controller?.stopImageStream();
      final nextIndex = (_currentCameraIndex + 1) % _cameras.length;
      await _initCamera(nextIndex);
    } finally {
      _isSwitchingCamera = false;
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      _flashEnabled = !_flashEnabled;
      await controller.setFlashMode(
        _flashEnabled ? FlashMode.torch : FlashMode.off,
      );

      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  Future<void> _setZoom(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final newZoom = zoom.clamp(_minZoom, _maxZoom);

    try {
      await controller.setZoomLevel(newZoom);

      if (!mounted) return;
      setState(() {
        _currentZoom = newZoom;
      });
    } catch (_) {}
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    if (!_faceDetected || !_faceCentered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coloca bien tu cara antes de continuar'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      await controller.stopImageStream();
      await controller.takePicture();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScreen(
            nextScreen: widget.nextScreen,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo capturar la foto'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _goNextDev() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingScreen(
          nextScreen: widget.nextScreen,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (!kIsWeb) {
      _faceDetector.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: const Color(0xFF05051C),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackButtonPurple(
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comprueba tu cara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Coloca tu cara dentro del círculo para comprobar que eres tú.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: const Color(0xFF5A2F8E),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: kIsWeb
                                  ? const Center(
                                      child: Text(
                                        'La detección facial en esta pantalla es solo para móvil.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : _isInitializing
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF9C4DFF),
                                          ),
                                        )
                                      : (controller != null &&
                                              controller.value.isInitialized)
                                          ? CameraPreview(controller)
                                          : const Center(
                                              child: Text(
                                                'No se pudo cargar la cámara',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                            ),
                            Center(
                              child: IgnorePointer(
                                child: Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _faceCentered
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF9C4DFF),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_faceCentered
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFF9C4DFF))
                                            .withValues(alpha: 0.25),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 18,
                              left: 18,
                              right: 18,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _faceCentered
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF7E2BE8),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    _faceStatus,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _faceCentered
                                          ? const Color(0xFFB7F7CC)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 104,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentZoom.toStringAsFixed(1)}x',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 56,
                              left: 24,
                              right: 24,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF9C4DFF),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  overlayColor:
                                      const Color(0xFF9C4DFF).withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value: _currentZoom,
                                  min: _minZoom,
                                  max: _maxZoom < 1.0 ? 1.0 : _maxZoom,
                                  onChanged: (value) => _setZoom(value),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF2E2E2E),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _CameraIconButton(
                              icon: _flashEnabled
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              onTap: _toggleFlash,
                            ),
                            _CaptureButton(
                              onTap: _capture,
                            ),
                            _CameraIconButton(
                              icon: Icons.cameraswitch,
                              onTap: _switchCamera,
                            ),
                          ],
                        ),
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _goNextDev,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: const Color(0xFF9C4DFF),
                                width: 1.5,
                              ),
                              color: const Color(0xFF9C4DFF).withValues(alpha: 0.15),
                            ),
                            child: const Center(
                              child: Text(
                                'Siguiente (dev)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButtonPurple extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButtonPurple({required this.onTap});

  @override
  State<_BackButtonPurple> createState() => _BackButtonPurpleState();
}

class _BackButtonPurpleState extends State<_BackButtonPurple> {
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

class _CaptureButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CaptureButton({required this.onTap});

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton> {
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
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CameraIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}