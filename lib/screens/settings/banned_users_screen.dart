import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/voo_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../chats/chats_screen.dart';
import '../ranking/ranking_screen.dart';
import '../retos/retos_screen.dart';

class BannedUsersScreen extends StatefulWidget {
  const BannedUsersScreen({super.key});

  @override
  State<BannedUsersScreen> createState() => _BannedUsersScreenState();
}

class _BannedUsersScreenState extends State<BannedUsersScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().cargarUsuariosSala();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleBan(SalaUsuarioModel user) async {
    final appState = context.read<AppState>();
    final bool isBanned = user.baneado;

    try {
      if (!isBanned) {
        final bool? confirmar = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => _ConfirmBanDialog(userName: user.nombre),
        );

        if (confirmar != true) return;

        await appState.banearUsuario(user.id);
      }
      // No hay unban por ahora — el backend no lo expone
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBanned
                ? '${user.nombre} ya no está baneado'
                : '${user.nombre} ha sido baneado',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final query = searchText.trim().toLowerCase();
    final allUsers = appState.salaUsuarios;
    final filtered = allUsers.where((u) => query.isEmpty || u.nombre.toLowerCase().contains(query)).toList();

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
                Row(
                  children: [
                    _PurpleBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Invitados',
                          style: TextStyle(
                            color: Color(0xFFD78BFF),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar invitado',
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    suffixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF151525),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: const Color(0xFF9C4DFF).withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF9C4DFF),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No se ha encontrado ningún invitado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.58),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            final bool isBanned = user.baneado;
                            final Color avatarColor = user.statusColor;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151525),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isBanned
                                      ? const Color(0xFFFF3B5C)
                                          .withValues(alpha: 0.75)
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isBanned ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isBanned
                                            ? const Color(0xFFFF3B5C)
                                            : avatarColor,
                                        width: 2.7,
                                      ),
                                    ),
                                    child: Icon(
                                      isBanned
                                          ? Icons.person_off_rounded
                                          : Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nombre,
                                          style: TextStyle(
                                            color: isBanned
                                                ? Colors.white.withValues(alpha: 0.55)
                                                : Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            decoration:
                                                isBanned ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isBanned
                                              ? 'Usuario baneado'
                                              : 'Usuario activo',
                                          style: TextStyle(
                                            color: isBanned
                                                ? const Color(0xFFFF3B5C)
                                                : const Color(0xFF66D63E),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isBanned ? null : () => _toggleBan(user),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isBanned
                                            ? const Color(0xFFFF3B5C)
                                                .withValues(alpha: 0.13)
                                            : const Color(0xFF151525),
                                        border: Border.all(
                                          color: isBanned
                                              ? const Color(0xFF66D63E)
                                              : const Color(0xFFFF3B5C),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        isBanned
                                            ? Icons.lock_open_rounded
                                            : Icons.block_rounded,
                                        color: isBanned
                                            ? const Color(0xFF66D63E)
                                            : const Color(0xFFFF3B5C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                VooBottomNavBar(
                  currentIndex: 4,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                      );
                    } else if (index == 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatsScreen(),
                        ),
                      );
                    } else if (index == 2) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RankingScreen(),
                        ),
                      );
                    } else if (index == 3) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RetosScreen(),
                        ),
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
        width: 46,
        height: 46,
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
          size: 19,
        ),
      ),
    );
  }
}

class _ConfirmBanDialog extends StatelessWidget {
  final String userName;

  const _ConfirmBanDialog({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFF3B5C),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B5C).withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF3B5C),
              size: 54,
            ),
            const SizedBox(height: 14),
            const Text(
              'Vas a eliminar a un usuario del evento',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Estás seguro de que quieres banear a $userName?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _DialogActionButton(
                    text: 'No',
                    color: const Color(0xFF52A9FF),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogActionButton(
                    text: 'Sí',
                    color: const Color(0xFFFF3B5C),
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _DialogActionButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 14,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}