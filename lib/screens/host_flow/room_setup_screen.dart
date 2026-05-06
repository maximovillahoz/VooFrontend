import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'room_code_screen.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cpController = TextEditingController();
  final TextEditingController grandPrizeController = TextEditingController();

  final List<TextEditingController> flashPrizeControllers = [
    TextEditingController(),
  ];

  String? selectedContext;
  String? selectedCapacity;
  bool _loading = false;

  @override
  void dispose() {
    roomNameController.dispose();
    addressController.dispose();
    cpController.dispose();
    grandPrizeController.dispose();

    for (final controller in flashPrizeControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addFlashPrizeField() {
    if (flashPrizeControllers.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes añadir hasta 5 premios flash'),
        ),
      );
      return;
    }

    setState(() {
      flashPrizeControllers.add(TextEditingController());
    });
  }

  void _removeFlashPrizeField(int index) {
    if (flashPrizeControllers.length <= 1) return;

    setState(() {
      flashPrizeControllers[index].dispose();
      flashPrizeControllers.removeAt(index);
    });
  }

  int _capacityToInt(String value) {
    switch (value) {
      case '15_30':
        return 30;
      case '30_50':
        return 50;
      case '50_plus':
        return 60;
      default:
        return 30;
    }
  }

  Future<Location> _getCoordinatesFromAddress() async {
    final direccion = addressController.text.trim();
    final cp = cpController.text.trim();

    final fullAddress = '$direccion, $cp, España';

    final locations = await locationFromAddress(fullAddress);

    if (locations.isEmpty) {
      throw Exception('No se pudo encontrar esa dirección');
    }

    return locations.first;
  }

  Future<void> _createRoom() async {
    final appState = context.read<AppState>();

    if (_loading) return;

    if (appState.userName == null ||
        appState.birthDate == null ||
        appState.estado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan datos del registro del host'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final location = await _getCoordinatesFromAddress();

      final premiosFlash = flashPrizeControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final result = await ApiService.registrarHost(
        nombre: appState.userName!,
        sexo: appState.sexo ?? false,
        fechaNacimiento: appState.birthDate!,
        foto: appState.profilePhoto ?? '',
        instagram: appState.instagram,
        estado: appState.estado!,
        respuestas: appState.respuestas,
        nombreSala: roomNameController.text.trim(),
        contexto: selectedContext!,
        aforo: _capacityToInt(selectedCapacity!),
        direccion: addressController.text.trim(),
        codigoPostal: int.parse(cpController.text.trim()),
        latitudSala: location.latitude,
        longitudSala: location.longitude,
        premioMayor: grandPrizeController.text.trim(),
        premiosFlash: premiosFlash,
        aceptaTerminos: appState.aceptaTerminos,
        aceptaPrivacidad: appState.aceptaPrivacidad,
        aceptaBiometria: appState.aceptaBiometria,
      );

      if (!mounted) return;

      appState.setUser(
        isHost: true,
        userName: result.nombreUsuario,
        roomCode: result.codigoSala,
        userId: result.usuarioId,
        salaId: result.salaId,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomCodeScreen(
            roomCode: result.codigoSala,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando sala: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue =
        roomNameController.text.trim().isNotEmpty &&
        selectedContext != null &&
        selectedCapacity != null &&
        addressController.text.trim().isNotEmpty &&
        cpController.text.trim().isNotEmpty &&
        grandPrizeController.text.trim().isNotEmpty;

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
                        'Creemos la sala',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configura la sala y prepara la experiencia para tus invitados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(text: 'Nombre de la sala'),
                      const SizedBox(height: 10),
                      _VooInput(
                        controller: roomNameController,
                        hintText: 'Escribe el nombre de la sala',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(text: 'Contexto'),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _OptionChip(
                            label: 'Fiesta en casa',
                            isSelected: selectedContext == 'fiesta_casa',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'fiesta_casa';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Cumpleaños',
                            isSelected: selectedContext == 'cumpleanos',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'cumpleanos';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Discoteca',
                            isSelected: selectedContext == 'discoteca',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'discoteca';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Cena',
                            isSelected: selectedContext == 'cena',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'cena';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Pool Party',
                            isSelected: selectedContext == 'pool_party',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'pool_party';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Previa',
                            isSelected: selectedContext == 'previa',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'previa';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Evento uni',
                            isSelected: selectedContext == 'evento_uni',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'evento_uni';
                              });
                            },
                          ),
                          _OptionChip(
                            label: 'Afterwork',
                            isSelected: selectedContext == 'afterwork',
                            color: const Color(0xFF9C4DFF),
                            onTap: () {
                              setState(() {
                                selectedContext = 'afterwork';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(text: 'Aforo'),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _OptionChip(
                            label: '15-30',
                            isSelected: selectedCapacity == '15_30',
                            color: const Color(0xFF22C55E),
                            onTap: () {
                              setState(() {
                                selectedCapacity = '15_30';
                              });
                            },
                          ),
                          _OptionChip(
                            label: '30-50',
                            isSelected: selectedCapacity == '30_50',
                            color: const Color(0xFF22C55E),
                            onTap: () {
                              setState(() {
                                selectedCapacity = '30_50';
                              });
                            },
                          ),
                          _OptionChip(
                            label: '+50',
                            isSelected: selectedCapacity == '50_plus',
                            color: const Color(0xFF22C55E),
                            onTap: () {
                              setState(() {
                                selectedCapacity = '50_plus';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(text: 'Dirección'),
                      const SizedBox(height: 10),
                      _VooInput(
                        controller: addressController,
                        hintText: 'Ej: Calle Mayor 10, Barcelona',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Formato recomendado: Calle + número + ciudad',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(text: 'CP'),
                      const SizedBox(height: 10),
                      _VooInput(
                        controller: cpController,
                        hintText: 'Código postal',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(
                        text: 'Premio mayor para el invitado ganador',
                      ),
                      const SizedBox(height: 10),
                      _VooInput(
                        controller: grandPrizeController,
                        hintText: 'Ej: Sorpresa',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(text: 'Premios para retos flash'),
                      const SizedBox(height: 10),
                      ...List.generate(flashPrizeControllers.length, (index) {
                        final canRemove = flashPrizeControllers.length > 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _VooInput(
                                  controller: flashPrizeControllers[index],
                                  hintText: 'Premio flash ${index + 1}',
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              if (canRemove) ...[
                                const SizedBox(width: 10),
                                _RemoveFlashButton(
                                  onTap: () => _removeFlashPrizeField(index),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AddButton(
                            onTap: _addFlashPrizeField,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoundBackButton(
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 20),
                          _NextButton(
                            enabled: canContinue && !_loading,
                            label: _loading ? 'Creando...' : 'Siguiente',
                            onTap: () {
                              if (!canContinue || _loading) return;
                              _createRoom();
                            },
                          ),
                        ],
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VooInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _VooInput({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
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
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 16,
                    spreadRadius: 1.2,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF22C55E),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF22C55E),
        ),
      ),
    );
  }
}

class _RemoveFlashButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveFlashButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.remove,
          color: Color(0xFFEF4444),
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
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _NextButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        widget.enabled ? const Color(0xFF22C55E) : Colors.grey;

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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: buttonColor,
            width: 2,
          ),
          boxShadow: _pressed && widget.enabled
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: buttonColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}