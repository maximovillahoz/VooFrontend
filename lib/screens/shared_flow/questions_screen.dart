import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../home/home_screen.dart';
import '../host_flow/room_setup_screen.dart';

class QuestionsScreen extends StatefulWidget {
  final bool isGuestFlow;
  final String estado;

  const QuestionsScreen({
    super.key,
    required this.estado,
    this.isGuestFlow = false,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final TextEditingController question1Controller = TextEditingController();
  final TextEditingController question2Controller = TextEditingController();
  final TextEditingController question3Controller = TextEditingController();

  bool _isSubmitting = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _loadedOnce) return;

      _loadedOnce = true;

      await context
          .read<AppState>()
          .cargarPreguntasRapidasPorEstado(widget.estado);
    });
  }

  @override
  void dispose() {
    question1Controller.dispose();
    question2Controller.dispose();
    question3Controller.dispose();
    super.dispose();
  }

  bool get _canContinue {
    return question1Controller.text.trim().isNotEmpty &&
        question2Controller.text.trim().isNotEmpty &&
        question3Controller.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_canContinue) return;

    final appState = context.read<AppState>();

    appState.setQuestionsData([
      question1Controller.text.trim(),
      question2Controller.text.trim(),
      question3Controller.text.trim(),
    ]);

    if (!widget.isGuestFlow) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RoomSetupScreen(),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await appState.registrarInvitadoEnBackend();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al entrar en la sala: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final preguntas = appState.preguntasRapidas;
    final bool isLoadingQuestions = appState.cargandoPreguntasRapidas;
    final String? error = appState.errorPreguntasRapidas;

    final bool hasQuestions = preguntas.length >= 3;
    final bool buttonEnabled = _canContinue && !_isSubmitting && hasQuestions;

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
                          enabled: !_isSubmitting,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Preguntas rápidas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Responde estas 3 preguntas para ver tu afinidad con otros invitados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (isLoadingQuestions)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9C4DFF),
                          ),
                        ),
                      )
                    else if (error != null)
                      Expanded(
                        child: Center(
                          child: _ErrorQuestionsBox(
                            message: 'No se han podido cargar las preguntas.',
                            onRetry: () {
                              context
                                  .read<AppState>()
                                  .cargarPreguntasRapidasPorEstado(
                                    widget.estado,
                                  );
                            },
                          ),
                        ),
                      )
                    else if (!hasQuestions)
                      Expanded(
                        child: Center(
                          child: _ErrorQuestionsBox(
                            message:
                                'El backend no ha devuelto 3 preguntas para este estado.',
                            onRetry: () {
                              context
                                  .read<AppState>()
                                  .cargarPreguntasRapidasPorEstado(
                                    widget.estado,
                                  );
                            },
                          ),
                        ),
                      )
                    else ...[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QuestionLabel(text: preguntas[0]),
                          const SizedBox(height: 12),
                          _QuestionInput(
                            controller: question1Controller,
                            hintText: 'Escribe tu respuesta',
                            enabled: !_isSubmitting,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 26),
                          _QuestionLabel(text: preguntas[1]),
                          const SizedBox(height: 12),
                          _QuestionInput(
                            controller: question2Controller,
                            hintText: 'Escribe tu respuesta',
                            enabled: !_isSubmitting,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 26),
                          _QuestionLabel(text: preguntas[2]),
                          const SizedBox(height: 12),
                          _QuestionInput(
                            controller: question3Controller,
                            hintText: 'Escribe tu respuesta',
                            enabled: !_isSubmitting,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _NextButton(
                          enabled: buttonEnabled,
                          isLoading: _isSubmitting,
                          onTap: _submit,
                        ),
                      ),
                    ],
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

class _ErrorQuestionsBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorQuestionsBox({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151525),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFF3B5C).withValues(alpha: 0.7),
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF3B5C),
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF9C4DFF),
                  width: 1.8,
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  color: Color(0xFF9C4DFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionLabel extends StatelessWidget {
  final String text;

  const _QuestionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _QuestionInput({
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_QuestionInput> createState() => _QuestionInputState();
}

class _QuestionInputState extends State<_QuestionInput> {
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
          boxShadow: _focused && widget.enabled
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
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: const Color(0xFF9C4DFF).withValues(alpha: 0.18),
                width: 1.4,
              ),
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
  final bool enabled;
  final VoidCallback onTap;

  const _RoundBackButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_RoundBackButton> createState() => _RoundBackButtonState();
}

class _RoundBackButtonState extends State<_RoundBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.4;

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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: opacity,
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
                color: const Color(0xFF8B3DFF).withValues(
                  alpha: _pressed ? 0.5 : 0.2,
                ),
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
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _NextButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color buttonColor =
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
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: buttonColor,
            width: 2,
          ),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(
                      alpha: _pressed ? 0.55 : 0.22,
                    ),
                    blurRadius: _pressed ? 18 : 12,
                    spreadRadius: _pressed ? 2 : 0.5,
                  ),
                ]
              : [],
        ),
        child: widget.isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: buttonColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Entrando...',
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Siguiente',
                style: TextStyle(
                  color: buttonColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}