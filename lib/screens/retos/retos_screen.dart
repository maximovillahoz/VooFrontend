import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reto_model.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../widgets/voo_bottom_nav_bar.dart';
import '../chats/chats_screen.dart';
import '../home/home_screen.dart';
import 'create_challenge_screen.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_screen.dart';

class RetosScreen extends StatefulWidget {
  const RetosScreen({super.key});

  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  bool _loading = true;
  String? _error;

  RetoModel? _anterior;
  RetoModel? _activo;
  RetoModel? _proximo;
  int? _lastRetosVersion;
  bool _isLoadingRetos = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await context.read<AppState>().iniciarSignalR();
      await _loadRetos(showLoading: true);
    });
  }

  Future<void> _loadRetos({bool showLoading = false}) async {
    if (_isLoadingRetos) return;

    final userId = context.read<AppState>().userId;

    if (userId == null || userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se ha encontrado tu usuario.';
      });
      return;
    }

    _isLoadingRetos = true;

    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final timeline = await ApiService.getRetosTimeline(userId);

      if (!mounted) return;

      setState(() {
        _anterior = timeline['anterior'];
        _activo = timeline['activo'];
        _proximo = timeline['proximo'];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los retos.';
      });
    } finally {
      _isLoadingRetos = false;
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Anterior';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';

    return 'Hace ${diff.inDays} días';
  }

  List<_ChallengeViewModel> _buildChallenges() {
    final list = <_ChallengeViewModel>[];

    if (_activo != null) {
      list.add(
        _ChallengeViewModel(
          title: _activo!.concepto,
          badgeText: 'Activo',
          pointsText: '+${_activo!.puntos} pt',
          color: const Color(0xFF22C55E),
        ),
      );
    }

    if (_proximo != null) {
      list.add(
        _ChallengeViewModel(
          title: _proximo!.concepto,
          badgeText: 'Próximo',
          pointsText: '+${_proximo!.puntos} pt',
          color: const Color(0xFFEAB308),
        ),
      );
    }

    if (_anterior != null) {
      list.add(
        _ChallengeViewModel(
          title: _anterior!.concepto,
          badgeText: _timeAgo(_anterior!.horaActivacion),
          pointsText: '+${_anterior!.puntos} pt',
          color: const Color(0xFFEF4444),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bool isHost = context.select<AppState, bool>((s) => s.isHost);
    final int retosVersion = context.select<AppState, int>((s) => s.retosVersion);

    if (_lastRetosVersion == null) {
      _lastRetosVersion = retosVersion;
    } else if (_lastRetosVersion != retosVersion) {
      _lastRetosVersion = retosVersion;

      Future.microtask(() {
        if (mounted) _loadRetos(showLoading: false);
      });
    }

    final challenges = _buildChallenges();

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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RetosTitle(),
                const SizedBox(height: 12),

                if (isHost) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _CreateChallengeButton(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateChallengeScreen(),
                          ),
                        );

                        if (mounted) _loadRetos();
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9C4DFF),
                          ),
                        )
                      : _error != null
                          ? _EmptyRetosMessage(
                              text: _error!,
                              onRetry: _loadRetos,
                            )
                          : challenges.isEmpty
                              ? _EmptyRetosMessage(
                                  text: 'Todavía no hay retos disponibles.',
                                  onRetry: _loadRetos,
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadRetos,
                                  color: const Color(0xFF9C4DFF),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: 12,
                                    ),
                                    itemCount: challenges.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 22),
                                    itemBuilder: (context, index) {
                                      return _WideChallengeCard(
                                        challenge: challenges[index],
                                      );
                                    },
                                  ),
                                ),
                ),

                const SizedBox(height: 8),

                VooBottomNavBar(
                  currentIndex: 3,
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
                      _loadRetos();
                    } else if (index == 4) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
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

class _EmptyRetosMessage extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _EmptyRetosMessage({
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onRetry,
        child: Text(
          '$text\nToca para recargar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RetosTitle extends StatelessWidget {
  const _RetosTitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Tus retos ',
            style: TextStyle(
              color: Color(0xFFD78BFF),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: 'V',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(
              color: Color(0xFFEAB308),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeViewModel {
  final String title;
  final String badgeText;
  final String pointsText;
  final Color color;

  const _ChallengeViewModel({
    required this.title,
    required this.badgeText,
    required this.pointsText,
    required this.color,
  });
}

class _WideChallengeCard extends StatefulWidget {
  final _ChallengeViewModel challenge;

  const _WideChallengeCard({
    required this.challenge,
  });

  @override
  State<_WideChallengeCard> createState() => _WideChallengeCardState();
}

class _WideChallengeCardState extends State<_WideChallengeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _borderAnimation;
  late final Animation<double> _scaleAnimation;

  bool get isActive => widget.challenge.color == const Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _glowAnimation = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _borderAnimation = Tween<double>(begin: 2.2, end: 3.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.012).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (isActive) {
      _controller.repeat(reverse: true);
    }


  }

  @override
  void didUpdateWidget(covariant _WideChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    if (!isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.challenge.color;

    if (!isActive) {
      return _ChallengeContainer(
        challenge: widget.challenge,
        color: color,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _ChallengeContainer(
            challenge: widget.challenge,
            color: color,
            borderWidth: _borderAnimation.value,
            shadows: [
              BoxShadow(
                color: color.withValues(alpha: _glowAnimation.value),
                blurRadius: 34,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: color.withValues(alpha: _glowAnimation.value * 0.7),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChallengeContainer extends StatelessWidget {
  final _ChallengeViewModel challenge;
  final Color color;
  final double borderWidth;
  final List<BoxShadow> shadows;

  const _ChallengeContainer({
    required this.challenge,
    required this.color,
    this.borderWidth = 2.2,
    this.shadows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF081328),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color,
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 88, bottom: 22),
            child: Text(
              challenge.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Text(
              challenge.badgeText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              challenge.pointsText,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateChallengeButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CreateChallengeButton({
    required this.onTap,
  });

  @override
  State<_CreateChallengeButton> createState() => _CreateChallengeButtonState();
}

class _CreateChallengeButtonState extends State<_CreateChallengeButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Color(0xFF9C4DFF), size: 18),
            SizedBox(width: 6),
            Text(
              'Crear reto',
              style: TextStyle(
                color: Color(0xFF9C4DFF),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}