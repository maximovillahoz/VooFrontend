import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/voo_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../chats/chats_screen.dart';
import '../ranking/ranking_screen.dart';
import '../retos/retos_screen.dart';
import 'banned_users_screen.dart';
import 'manual_screen.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Future<void> _confirmarCerrarSala(AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151525),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF9C4DFF), width: 1.5),
        ),
        title: const Text(
          '¿Cerrar la sala?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Se eliminará la sala y todos los datos. Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFFD78BFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sala',
                style: TextStyle(color: Color(0xFFFF3B5C))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await appState.cerrarSala();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cerrar sala: $e')));
    }
  }

  Future<void> _confirmarSalirSala(AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151525),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF9C4DFF), width: 1.5),
        ),
        title: const Text(
          '¿Salir de la sala?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Perderás tu progreso y acceso a los chats activos.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFFD78BFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir',
                style: TextStyle(color: Color(0xFFFF3B5C))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await appState.salirDeSala();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al salir: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool isHost = appState.isHost;

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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          'Ajustes',
                          style: TextStyle(
                            color: Color(0xFFD78BFF),
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _ProfileCard(appState: appState),
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: 'Ayuda',
                          children: [
                            _SettingsRow(
                              title: 'Manual de uso',
                              icon: Icons.menu_book_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManualScreen(),
                                  ),
                                );
                              },
                            ),
                           _SettingsRow(
                                title: 'Reportar incidencia',
                                icon: Icons.report_problem_outlined,
                                onTap: () async {
                                  final uri = Uri(
                                    scheme: 'mailto',
                                    path: 'soportevoo@gmail.com',
                                    queryParameters: {
                                      'subject': 'Incidencia VOO',
                                      'body': 'Describe aquí tu incidencia:',
                                    },
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _RoomCard(appState: appState),
                        const SizedBox(height: 24),
                        if (isHost)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ActionButton(
                                text: 'Banear usuario',
                                color: const Color(0xFF9C4DFF),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BannedUsersScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 14),
                              _ActionButton(
                                text: 'Cerrar sala',
                                color: const Color(0xFFFF3B5C),
                                onTap: () => _confirmarCerrarSala(appState),
                              ),
                            ],
                          )
                        else
                          _ActionButton(
                            text: 'Salir de la sala',
                            color: const Color(0xFFFF3B5C),
                            onTap: () => _confirmarSalirSala(appState),
                          ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),

                VooBottomNavBar(
                  currentIndex: 4,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    } else if (index == 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatsScreen()),
                      );
                    } else if (index == 2) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RankingScreen()),
                      );
                    } else if (index == 3) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RetosScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AppState appState;

  const _ProfileCard({
    required this.appState
  });

  @override
  Widget build(BuildContext context) {
    final nombre = appState.userName ?? 'Usuario';
    final nivel = appState.nivelId ?? 'Ninguno';
    final premios = appState.premios;

    String edadStr = '—';
    final bd = appState.birthDate;
    if (bd != null) {
      final hoy = DateTime.now();
      int edad = hoy.year - bd.year;
      if (hoy.month < bd.month || (hoy.month == bd.month && hoy.day < bd.day)) {edad--;}
      edadStr = '$edad años';
    }

    final estado = appState.estado?.toLowerCase().trim() ?? '';

    Color estadoColor;

    switch (estado) {
      case 'amigos':
        estadoColor = const Color(0xFFEAB308); // amarillo
        break;
      case 'pareja':
        estadoColor = const Color(0xFFEF4444); // rojo
        break;
      case 'soltero':
      default:
        estadoColor = const Color(0xFF22C55E); // verde
        break;
    }

    ImageProvider? profileImage;

    final foto = appState.profilePhoto;
    if (foto != null && foto.trim().isNotEmpty) {
      try {
        var cleanBase64 = foto.trim();

        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        profileImage = MemoryImage(base64Decode(cleanBase64));
      } catch (_) {
        profileImage = null;
      }
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perfil',
            style: TextStyle(
              color: Color(0xFFD78BFF),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: estadoColor,
                        width: 3.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImage != null
                          ? Image(
                              image: profileImage,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 38,
                            ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: estadoColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF05051C),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ProfileInfo(title: nombre, subtitle: edadStr),
                    _ProfileInfo(title: nivel, subtitle: 'Nivel'),
                    _ProfileInfo(title: '${premios.length}', subtitle: 'Premios'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ProfileInfo({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final AppState appState;

  const _RoomCard({
    required this.appState
  });

  @override
  Widget build(BuildContext context) {
    final isHost = appState.isHost;
    final codigo = appState.roomCode ?? '---';
    final invitados = appState.salaUsuarios.where((u) => !u.baneado).length;
    final baneados = appState.baneadosCount;
    final matches = appState.matchCount;
    
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sala',
            style: TextStyle(
              color: Color(0xFFD78BFF),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoomInfo(title: codigo, subtitle: 'Código'),
              _RoomInfo(title: '$invitados', subtitle: 'Invitados'),
              _RoomInfo(
                title: isHost ? '$baneados' : '$matches',
                subtitle: isHost ? 'Baneados' : 'Match',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomInfo extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RoomInfo({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD78BFF),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFD78BFF),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151525),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF9C4DFF).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}