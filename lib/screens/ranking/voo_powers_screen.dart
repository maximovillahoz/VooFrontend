import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../state/app_state.dart';

class VooPowersScreen extends StatefulWidget {
  const VooPowersScreen({super.key});

  @override
  State<VooPowersScreen> createState() => _VooPowersScreenState();
}

class _VooPowersScreenState extends State<VooPowersScreen> {
  SalaUsuarioModel? _usuario;
  List<PoderModel> _todosLosPoderes = [];
  List<PoderModel> _poderesDesbloqueados = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final userId = context.read<AppState>().userId;

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se encontró el usuario';
      });
      return;
    }

    try {
      final results = await Future.wait([
        ApiService.getUsuarioPorId(userId),
        ApiService.getTodosLosPoderes(),
        ApiService.getPoderesUsuario(userId),
      ]);

      if (!mounted) return;

      setState(() {
        _usuario = results[0] as SalaUsuarioModel;
        _todosLosPoderes = results[1] as List<PoderModel>;
        _poderesDesbloqueados = results[2] as List<PoderModel>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error cargando poderes: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se han podido cargar los poderes';
      });
    }
  }

  String _poderActivo() {
    final puntosActuales = _usuario?.puntos ?? 0;

    final poderes =
        _todosLosPoderes.isNotEmpty ? _todosLosPoderes : _fallbackPoderes();

    final desbloqueados = poderes
        .where((poder) => puntosActuales >= poder.puntosNecesarios)
        .toList()
      ..sort((a, b) => b.puntosNecesarios.compareTo(a.puntosNecesarios));

    if (desbloqueados.isEmpty) return 'Ninguno';

    return _nombrePoder(desbloqueados.first.nivelId);
  }

  String _nombrePoder(String nivelId) {
    switch (nivelId.toLowerCase()) {
      case 'chismoso':
        return 'El Chismoso';
      case 'cupido':
        return 'El Cupido';
      case 'rey':
        return 'Rey de la pista';
      default:
        return nivelId;
    }
  }

  bool _estaDesbloqueado(PoderModel poder) {
    final puntosActuales = _usuario?.puntos ?? 0;
    return puntosActuales >= poder.puntosNecesarios;
  }

  Color _colorEstado(String estado) {
    final value = estado.toLowerCase().trim();

    if (value.contains('amarillo') ||
        value.contains('amigos') ||
        value.contains('amigo') ||
        value.contains('complicado')) {
      return const Color(0xFFEAB308);
    }

    if (value.contains('rojo') || value.contains('pareja')) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF66D63E);
  }

  _PowerConfig _configPoder(String nivelId) {
    switch (nivelId.toLowerCase()) {
      case 'chismoso':
        return const _PowerConfig(
          color: Color(0xFF66D63E),
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Nivel 1 · El Chismoso',
        );
      case 'cupido':
        return const _PowerConfig(
          color: Color(0xFFEAB308),
          icon: Icons.bolt_rounded,
          title: 'Nivel 2 · El Cupido',
        );
      case 'rey':
        return const _PowerConfig(
          color: Color(0xFFFF3B5C),
          icon: Icons.workspace_premium_rounded,
          title: 'Nivel 3 · Rey de la pista',
        );
      default:
        return _PowerConfig(
          color: Colors.white24,
          icon: Icons.star_outline_rounded,
          title: nivelId,
        );
    }
  }

  List<PoderModel> _fallbackPoderes() {
    return [
      PoderModel(
        id: 'local-1',
        nivelId: 'chismoso',
        puntosNecesarios: 50,
        conceptoPoder:
            'Descubre quién ha visto tu perfil y consigue una pequeña ventaja antes de empezar una conversación.',
      ),
      PoderModel(
        id: 'local-2',
        nivelId: 'cupido',
        puntosNecesarios: 100,
        conceptoPoder:
            'Lanza un reto flash anónimo para dos personas y crea el momento perfecto para romper el hielo.',
      ),
      PoderModel(
        id: 'local-3',
        nivelId: 'rey',
        puntosNecesarios: 150,
        conceptoPoder:
            'Desbloquea el poder de lanzar un reto personalizado a toda la sala y poner el juego patas arriba.',
      ),
    ];
  }

  ImageProvider? _profileImage(String? foto) {
    if (foto == null || foto.trim().isEmpty) return null;

    final value = foto.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }

    try {
      var cleanBase64 = value;

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
    final appState = context.watch<AppState>();

    final userName = _usuario?.nombre ?? appState.userName ?? 'Usuario';
    final estado = _usuario?.estado ?? appState.estado ?? 'verde';
    final puntos = _usuario?.puntos ?? 0;
    final foto = _usuario?.foto ?? appState.profilePhoto;
    final colorEstado = _colorEstado(estado);
    final image = _profileImage(foto);

    final poderes =
        _todosLosPoderes.isNotEmpty ? _todosLosPoderes : _fallbackPoderes();

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
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF9C4DFF),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CircleBackButton(
                            onTap: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Poderes Voo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD78BFF),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 54),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Hola ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: userName,
                              style: const TextStyle(
                                color: Color(0xFFD78BFF),
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF9C4DFF),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Consigue puntos, sube de nivel y desbloquea ventajas dentro de la sala.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 116,
                                height: 116,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorEstado,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorEstado.withValues(alpha: 0.22),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: image != null
                                      ? Image(
                                          image: image,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 62,
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: colorEstado,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF05051C),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoLine(
                                  label: 'Estado',
                                  value: estado,
                                ),
                                const SizedBox(height: 10),
                                _InfoLine(
                                  label: 'Puntos',
                                  value: '$puntos pts',
                                ),
                                const SizedBox(height: 10),
                                _InfoLine(
                                  label: 'Poder activo',
                                  value: _poderActivo(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151525),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  const Color(0xFFFF3B5C).withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.74),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: poderes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final poder = poderes[index];
                            final config = _configPoder(poder.nivelId);
                            final desbloqueado = _estaDesbloqueado(poder);
                            return _PowerCard(
                              borderColor: config.color,
                              icon: config.icon,
                              title: config.title,
                              points: '${poder.puntosNecesarios} pts',
                              description: poder.conceptoPoder,
                              desbloqueado: desbloqueado,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _PowerConfig {
  final Color color;
  final IconData icon;
  final String title;

  const _PowerConfig({
    required this.color,
    required this.icon,
    required this.title,
  });
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label\n',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.58),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  final Color borderColor;
  final IconData icon;
  final String title;
  final String points;
  final String description;
  final bool desbloqueado;

  const _PowerCard({
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.points,
    required this.description,
    required this.desbloqueado,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = desbloqueado ? borderColor : Colors.white24;
    final Color bgColor =
        desbloqueado ? const Color(0xFF101020) : const Color(0xFF0A0A18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color,
          width: 2.8,
        ),
        boxShadow: desbloqueado
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 0.7,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          desbloqueado
              ? Icon(
                  icon,
                  color: color,
                  size: 54,
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 16,
                    ),
                  ],
                )
              : const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white24,
                  size: 54,
                ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    desbloqueado ? '✓ $points' : points,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    color: desbloqueado
                        ? Colors.white.withValues(alpha: 0.88)
                        : Colors.white38,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _CircleBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CircleBackButton({
    required this.onTap,
  });

  @override
  State<_CircleBackButton> createState() => _CircleBackButtonState();
}

class _CircleBackButtonState extends State<_CircleBackButton> {
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
              color: const Color(0xFF8B3DFF).withValues(
                alpha: _pressed ? 0.5 : 0.22,
              ),
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