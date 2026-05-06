import 'package:flutter/material.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final TextEditingController retoController = TextEditingController();
  final TextEditingController puntosController = TextEditingController();
  final TextEditingController premioController = TextEditingController();

  final List<String> durationOptions = ['30 min', '1 h', '2 h'];
  String selectedDuration = '30 min';

  @override
  void dispose() {
    retoController.dispose();
    puntosController.dispose();
    premioController.dispose();
    super.dispose();
  }

  bool get canCreate =>
      retoController.text.trim().isNotEmpty &&
      puntosController.text.trim().isNotEmpty;

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _PurpleBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: _ChallengeTitle(),
                    ),
                    const SizedBox(width: 54),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Crea un reto para animar la sala y repartir puntos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(
                            text: 'Describe el reto',
                            icon: Icons.flag_rounded,
                          ),
                          const SizedBox(height: 10),
                          _StyledInput(
                            controller: retoController,
                            hintText: 'Ej: consigue una foto con alguien que no conozcas',
                            maxLines: 5,
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel(
                                      text: 'Puntos',
                                      icon: Icons.stars_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    _StyledInput(
                                      controller: puntosController,
                                      hintText: '50',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _DurationDropdown(
                                  selectedDuration: selectedDuration,
                                  options: durationOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      selectedDuration = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          const _FieldLabel(
                            text: 'Premio opcional',
                            icon: Icons.card_giftcard_rounded,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StyledInput(
                                  controller: premioController,
                                  hintText: 'Ej: una copa, elegir el siguiente reto...',
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _AddPrizeButton(
                                onTap: () => _showPrizeDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                _CreateButton(
                  enabled: canCreate,
                  onTap: () {
                    if (!canCreate) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reto creado'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrizeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151525),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: Color(0xFF9C4DFF),
              width: 1.6,
            ),
          ),
          title: const Text(
            'Añadir premio',
            style: TextStyle(
              color: Color(0xFFD78BFF),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: premioController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Ej: 1 copa, elegir reto, premio especial...',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Color(0xFF66D63E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChallengeTitle extends StatelessWidget {
  const _ChallengeTitle();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Crear reto ',
            style: TextStyle(
              color: Color(0xFFD78BFF),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: 'V',
            style: TextStyle(
              color: const Color(0xFF66D63E),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: const Color(0xFF66D63E).withValues(alpha: 0.85),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(
              color: const Color(0xFFEAB308),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.85),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(
              color: const Color(0xFFFF3B5C),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: const Color(0xFFFF3B5C).withValues(alpha: 0.85),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _FieldLabel({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFD78BFF),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD78BFF),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF151525),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF9C4DFF).withValues(alpha: 0.55),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C4DFF).withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? hintText;

  const _StyledInput({
    required this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF101020),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: const Color(0xFF9C4DFF).withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF9C4DFF),
            width: 2.2,
          ),
        ),
      ),
    );
  }
}

class _AddPrizeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPrizeButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3B1452),
              Color(0xFF24103A),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF9C4DFF),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B3DFF).withValues(alpha: 0.22),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _DurationDropdown extends StatelessWidget {
  final String selectedDuration;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DurationDropdown({
    required this.selectedDuration,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(
          text: 'Duración',
          icon: Icons.timer_rounded,
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF101020),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF9C4DFF).withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDuration,
              dropdownColor: const Color(0xFF151525),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              iconEnabledColor: const Color(0xFFD78BFF),
              isExpanded: true,
              items: options.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _PurpleBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PurpleBackButton({
    required this.onTap,
  });

  @override
  State<_PurpleBackButton> createState() => _PurpleBackButtonState();
}

class _PurpleBackButtonState extends State<_PurpleBackButton> {
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
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3B1452),
              Color(0xFF24103A),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF9C4DFF),
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B3DFF).withValues(alpha: _pressed ? 0.5 : 0.22),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _CreateButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _CreateButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? const Color(0xFF66D63E) : Colors.grey;

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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: 2.2,
          ),
          boxShadow: _pressed && widget.enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.34),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          'Crear reto',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}