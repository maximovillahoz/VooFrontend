import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../shared_flow/camera_screen.dart';
import 'join_room_screen.dart';

import 'package:flutter/gestures.dart';
import '../shared_flow/terms_screen.dart';

class RegisterGuestScreen extends StatefulWidget {
  const RegisterGuestScreen({super.key});

  @override
  State<RegisterGuestScreen> createState() => _RegisterGuestScreenState();
}

class _RegisterGuestScreenState extends State<RegisterGuestScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Uint8List? _profileImageBytes;
  DateTime? _selectedBirthDate;
  bool? selectedSex;
  bool _isPickingImage = false;
  bool _requestingCameraPermission = false;
  bool _acceptedTerms = false;

  bool get canContinue {
  return nameController.text.trim().isNotEmpty &&
      selectedSex != null &&
      birthDateController.text.trim().isNotEmpty &&
      _profileImageBytes != null &&
      _acceptedTerms;
  }

  @override
  void dispose() {
    nameController.dispose();
    birthDateController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const TermsScreen(),
      ),
    );

    if (!mounted) return;

    if (accepted == true) {
      setState(() {
        _acceptedTerms = true;
      });
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      setState(() {
        _isPickingImage = true;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (!mounted) return;
        setState(() {
          _isPickingImage = false;
        });
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        _profileImageBytes = bytes;
        _isPickingImage = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isPickingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo seleccionar la imagen'),
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14142E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Añadir foto de perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SourceCard(
                        icon: Icons.photo_library_outlined,
                        label: 'Galería',
                        color: const Color(0xFF5A35C8),
                        onTap: () {
                          Navigator.pop(context);
                          _pickProfileImage(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SourceCard(
                        icon: Icons.camera_alt_outlined,
                        label: 'Cámara',
                        color: const Color(0xFF8E3DFF),
                        onTap: () {
                          Navigator.pop(context);
                          _pickProfileImage(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isAtLeast16(DateTime date) {
    final today = DateTime.now();
    var age = today.year - date.year;

    if (today.month < date.month ||
        (today.month == date.month && today.day < date.day)) {
      age--;
    }

    return age >= 16;
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Selecciona tu fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9C4DFF),
              surface: Color(0xFF14142E),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB15CFF),
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF14142E)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!_isAtLeast16(pickedDate)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ser mayor de 16 años para usar Voo.'),
        ),
      );

      return;
    }

    final formatted =
        '${pickedDate.day.toString().padLeft(2, '0')}/'
        '${pickedDate.month.toString().padLeft(2, '0')}/'
        '${pickedDate.year}';

    setState(() {
      _selectedBirthDate = pickedDate;
      birthDateController.text = formatted;
    });
  }

  Future<void> _requestCameraAndContinue() async {
    if (!canContinue || _requestingCameraPermission) return;

    setState(() {
      _requestingCameraPermission = true;
    });

    try {
      final status = await Permission.camera.request();

      if (!mounted) return;

      if (status.isGranted) {
        if (_selectedBirthDate == null || _profileImageBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Completa tu fecha y tu foto para continuar.'),
            ),
          );
          return;
        }

        context.read<AppState>().setRegisterData(
          userName: nameController.text.trim(),
          birthDate: _selectedBirthDate!,
          profilePhoto: base64Encode(_profileImageBytes!),
          sexo: selectedSex!,
          instagram: instagramController.text.trim().isEmpty
              ? null
              : instagramController.text.trim(),
          aceptaTerminos: true,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CameraScreen(
              nextScreen: JoinRoomScreen(),
            ),
          ),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el permiso de cámara en ajustes para continuar.'),
          ),
        );
        await openAppSettings();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes continuar sin aceptar el permiso de cámara.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestingCameraPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051C),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Primero te vamos a\nregistrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Center(
                    child: GestureDetector(
                      onTap: _isPickingImage ? null : _showImageSourcePicker,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 126,
                            height: 126,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF18183A),
                                  Color(0xFF101028),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: _profileImageBytes != null
                                    ? const Color(0xFF9C4DFF)
                                    : const Color(0xFF4E2A88),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_profileImageBytes != null
                                          ? const Color(0xFF9C4DFF)
                                          : const Color(0xFF4E2A88))
                                      .withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isPickingImage
                                  ? const Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFFB15CFF),
                                          ),
                                        ),
                                      ),
                                    )
                                  : _profileImageBytes != null
                                      ? Image.memory(
                                          _profileImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.person_outline,
                                          size: 54,
                                          color: Colors.white70,
                                        ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _profileImageBytes != null
                                ? 'Foto de perfil añadida'
                                : 'Añade tu foto de perfil',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  _StyledInput(
                    controller: nameController,
                    hintText: 'Nombre',
                    prefixIcon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _SexSelector(
                    selectedSex: selectedSex,
                    onChanged: (value) {
                      setState(() {
                        selectedSex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: birthDateController,
                    hintText: 'Fecha de nacimiento',
                    prefixIcon: Icons.cake_outlined,
                    suffixIcon: Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  _StyledInput(
                    controller: instagramController,
                    hintText: 'Instagram (opcional)',
                    prefixIcon: Icons.alternate_email,
                    onChanged: (_) {},
                  ),

                  const SizedBox(height: 18),

                  _TermsBox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value;
                      });
                    },
                    onTapTerms: _openTerms,
                  ),

                  const SizedBox(height: 18),

                  if (!canContinue)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Completa nombre, sexo, fecha de nacimiento, foto de perfil y acepta los términos para continuar.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  Center(
                    child: _MainGradientButton(
                      enabled: canContinue && !_requestingCameraPermission,
                      label: _requestingCameraPermission
                          ? 'Comprobando...'
                          : 'Siguiente',
                      onTap: _requestCameraAndContinue,
                    ),
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

class _SexSelector extends StatelessWidget {
  final bool? selectedSex;
  final ValueChanged<bool> onChanged;

  const _SexSelector({
    required this.selectedSex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SexButton(
            label: 'Hombre',
            icon: Icons.male_rounded,
            selected: selectedSex == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SexButton(
            label: 'Mujer',
            icon: Icons.female_rounded,
            selected: selectedSex == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _SexButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SexButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? const Color(0xFF9C4DFF) : const Color(0xFF4A267D);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF181835),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor,
            width: selected ? 2.4 : 1.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF9C4DFF).withValues(alpha: 0.24),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFFB15CFF) : Colors.white54,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onBack();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
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
                  color: const Color(0xFF8B3DFF)
                      .withValues(alpha: _pressed ? 0.55 : 0.16),
                  blurRadius: _pressed ? 22 : 10,
                  spreadRadius: _pressed ? 1.5 : 0.5,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const _StyledInput({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white54,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFFA95BFF),
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: const Color(0xFFA95BFF),
              ),
        filled: true,
        fillColor: const Color(0xFF181835),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFF4A267D),
            width: 1.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFF9C4DFF),
            width: 2.2,
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(Colors.black, color, 0.28)!,
              Color.lerp(Colors.black, color, 0.52)!,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Color.lerp(Colors.black, color, 0.7)!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainGradientButton extends StatefulWidget {
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _MainGradientButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  State<_MainGradientButton> createState() => _MainGradientButtonState();
}

class _MainGradientButtonState extends State<_MainGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    final leftColor = enabled
        ? const Color(0xFF4B175E)
        : const Color(0xFF2E2E38);
    final rightColor = enabled
        ? const Color(0xFF2A083D)
        : const Color(0xFF24242C);
    final borderColor = enabled
        ? const Color(0xFF7E2BE8)
        : const Color(0xFF4A4A54);

    return GestureDetector(
      onTapDown: (_) {
        if (enabled) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (enabled) {
          setState(() => _pressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [leftColor, rightColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: borderColor,
            width: 2.2,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B3DFF)
                        .withValues(alpha: _pressed ? 0.6 : 0.22),
                    blurRadius: _pressed ? 26 : 14,
                    spreadRadius: _pressed ? 2 : 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TermsBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapTerms;

  const _TermsBox({
    required this.value,
    required this.onChanged,
    required this.onTapTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181835),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? const Color(0xFF9C4DFF) : const Color(0xFF4A267D),
          width: value ? 2 : 1.4,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF9C4DFF),
            checkColor: Colors.white,
            side: const BorderSide(
              color: Color(0xFF9C4DFF),
              width: 1.6,
            ),
            onChanged: (checked) => onChanged(checked ?? false),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.35,
                ),
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'términos y condiciones',
                    style: const TextStyle(
                      color: Color(0xFFB15CFF),
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onTapTerms,
                  ),
                  const TextSpan(
                    text:
                        ', la política de privacidad y el tratamiento de datos biométricos.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}