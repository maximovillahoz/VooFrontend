import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/request_model.dart';
import '../../state/app_state.dart';
import '../../widgets/sent_request_dialog.dart';
import '../../widgets/user_interaction_dialog.dart';
import '../../widgets/voo_bottom_nav_bar.dart';
import '../chats/chats_screen.dart';
import 'profile_qr_screen.dart';
import '../retos/retos_screen.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/api_service.dart';
import '../chats/chat_conversation_screen.dart';
import '../../models/chat_preview_state.dart';
import '../../models/chat_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _knownUserIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await context.read<AppState>().cargarUsuariosSala();

      if (!mounted) return;

      final users = context.read<AppState>().salaUsuarios;
      _knownUserIds.addAll(users.map((user) => user.id));

      await context.read<AppState>().iniciarSignalR();
    });
  }

  String _requestTypeLabel(RequestType type) {
    switch (type) {
      case RequestType.truth:
        return 'Verdad';
      case RequestType.dare:
        return 'Reto';
      case RequestType.messageRequest:
        return 'Mensaje';
    }
  }

  Color _colorPorEstado(String estado) {
  final value = estado.toLowerCase().trim();

  if (value.contains('amigos') || value.contains('buscando amigos')) {
    return const Color(0xFFEAB308); // amarillo
  }

  if (value.contains('pareja')) {
    return const Color(0xFFEF4444); // rojo
  }

    return const Color(0xFF22C55E); // verde
}

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final bool isHost = appState.isHost;
    final String nombrePerfil = appState.userName ?? 'Usuario';
    final String codigoSala = appState.roomCode ?? '---';

    final visibleUsers = appState.salaUsuarios
      .where((user) => !user.baneado)
      .toList()
    ..sort((a, b) {
      final aTieneSolicitud = appState.getPendingRequestForUser(a.id) != null ||
          appState.shouldHideUserFromHome(a.id);

      final bTieneSolicitud = appState.getPendingRequestForUser(b.id) != null ||
          appState.shouldHideUserFromHome(b.id);

      if (aTieneSolicitud == bTieneSolicitud) return 0;
      return aTieneSolicitud ? 1 : -1;
    });

    final RequestModel? blockingIncoming = appState.blockingIncomingRequest;
    final RequestModel? activeAccepted = appState.activeAcceptedRequest;

    final bool lockHome = blockingIncoming != null || activeAccepted != null;

    void abrirChatConUsuario(SalaUsuarioModel user) {
      final appState = context.read<AppState>();

      ChatModel? chat;

      try {
        chat = appState.dynamicChats.firstWhere(
          (c) =>
              c.otherUserId == user.id &&
              c.previewState != ChatPreviewState.missionBusy,
        );
      } catch (_) {
        chat = null;
      }

      if (chat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.nombre} todavía no ha aceptado la solicitud.',
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            isHost: appState.isHost,
            chatId: chat!.id,
            targetUserId: chat.otherUserId,
            chatName: chat.userName,
            chatFoto: chat.foto,
            statusColor: chat.statusColor,
          ),
        ),
      );
    }

    Future<void> openInteractionPopup(SalaUsuarioModel user) async {
      if (lockHome) return;

      final userColor = _colorPorEstado(user.estado);

      final existingPending = appState.getPendingRequestForUser(user.id);
      if (existingPending != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ya tienes una solicitud pendiente con ${user.nombre}',
            ),
          ),
        );
        return;
      }

      final DialogRequestResult? result =
            await showDialog<DialogRequestResult>(
          context: context,
          barrierDismissible: true,
          builder: (_) => UserInteractionDialog(
          targetUserId: user.id,
          targetUserName: user.nombre,
          targetUserAge: user.edad,
          statusColor: userColor,
          targetUserFoto: user.foto,
        ),
      );

      if (result == null || !context.mounted) return;

      await appState.sendRequest(
        targetUserId: result.targetUserId,
        targetUserName: result.targetUserName,
        type: result.type,
        content: result.content,
        statusColor: userColor,
      );

      final dialogData = switch (result.type) {
        RequestType.truth => (
            'Verdad enviada',
            'Tu solicitud de verdad se ha enviado a ${result.targetUserName}',
          ),
        RequestType.dare => (
            'Reto enviado',
            'Tu solicitud de reto se ha enviado a ${result.targetUserName}',
          ),
        RequestType.messageRequest => (
            'Mensaje enviado',
            'Tu solicitud de mensaje se ha enviado a ${result.targetUserName}',
          ),
      };

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SentRequestDialog(
          title: dialogData.$1,
          subtitle: dialogData.$2,
        ),
      );
    }

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
          child: Stack(
            children: [
              // ─── CONTENIDO PRINCIPAL ──────────────────────────────────
              // El Column principal está FUERA del IgnorePointer
              // para que el nav bar siempre sea accesible
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solo la parte superior y la lista quedan bloqueadas
                    Expanded(
                      child: IgnorePointer(
                        ignoring: lockHome,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                              saludo: 'Hola $nombrePerfil!',
                              codigoSala: codigoSala,
                              onQrTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileQrScreen(
                                      isHost: isHost,
                                      userName: nombrePerfil,
                                      roomCode: codigoSala,
                                      userId: appState.userId ?? '',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Invitados en la sala',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: visibleUsers.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No hay más invitados disponibles ahora mismo',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.60),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      physics: lockHome
                                          ? const NeverScrollableScrollPhysics()
                                          : const BouncingScrollPhysics(),
                                      itemCount: visibleUsers.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final user = visibleUsers[index];
                                        final userColor =
                                            _colorPorEstado(user.estado);
 
                                        final interactionRequest = appState
                                            .getInteractionRequestForUser(
                                                user.id);
 
                                        final bool hasRequest =
                                            interactionRequest != null ||
                                                appState.shouldHideUserFromHome(
                                                    user.id);
 
                                        final bool isRejected =
                                            interactionRequest?.status ==
                                                RequestStatus.rejected;
 
                                        final String? requestLabel =
                                            interactionRequest == null
                                                ? null
                                                : interactionRequest.status ==
                                                        RequestStatus.rejected
                                                    ? 'Solicitud rechazada'
                                                    : '${_requestTypeLabel(interactionRequest.type)} pendiente';
 
                                        final bool isNewUser =
                                            !_knownUserIds.contains(user.id);
 
                                        if (isNewUser) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            _knownUserIds.add(user.id);
                                          });
                                        }
 
                                        return _AnimatedGuestEntry(
                                          key: ValueKey(user.id),
                                          animate: isNewUser,
                                          glowColor: userColor,
                                          child: _GuestCard(
                                            name: user.nombre,
                                            age: user.edad,
                                            foto: user.foto,
                                            statusColor: userColor,
                                            hasRequestSent: hasRequest,
                                            pendingLabel: requestLabel,
                                            pendingLabelColor: isRejected
                                                ? const Color(0xFFFF3B5C)
                                                : const Color(0xFFEAB308),
                                            onTap: isRejected
                                                ? () {
                                                    context
                                                        .read<AppState>()
                                                        .reopenRejectedIncomingRequest(
                                                            user.id);
                                                  }
                                                : hasRequest
                                                    ? () =>
                                                        abrirChatConUsuario(
                                                            user)
                                                    : () =>
                                                        openInteractionPopup(
                                                            user),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
 
                    const SizedBox(height: 10),
 
                    // ─── NAV BAR FUERA DEL IgnorePointer ─────────────────
                    // Siempre accesible aunque haya popup en el home
                    VooBottomNavBar(
                      currentIndex: 0,
                      onTap: (index) {
                        // index 0 es home, no navegamos
                        if (index == 0) return;
 
                        if (index == 1) {
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
 
              // ─── OVERLAY OSCURO cuando hay popup ─────────────────────
              // Solo cubre la lista, NO el nav bar
              if (lockHome)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
 
              // ─── POPUP DE SOLICITUD ENTRANTE ─────────────────────────
              if (blockingIncoming != null)
                Center(
                  child: _IncomingRequestPopup(
                    request: blockingIncoming,
                    onReject: () {
                      context
                          .read<AppState>()
                          .rejectIncomingRequest(blockingIncoming.id);
                    },
                    onAccept: () async {
                      await context
                          .read<AppState>()
                          .acceptIncomingRequest(blockingIncoming.id);
                    },
                  ),
                ),
 
              // ─── POPUP DE RESPUESTA A SOLICITUD ACEPTADA ─────────────
              if (activeAccepted != null)
                Center(
                  child: _AcceptedRequestResponsePopup(
                    request: activeAccepted,
                    onBack: () {
                      context
                          .read<AppState>()
                          .restoreAcceptedRequestToPending();
                    },
                    onSendResponse: (responseText) async {
                      await context
                          .read<AppState>()
                          .finishAcceptedRequestResponse(responseText);
 
                      if (!mounted) return;
 
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const SentRequestDialog(
                          title: 'Mensaje enviado',
                          subtitle:
                              'Ya podéis seguir hablando en vuestro chat.',
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedGuestEntry extends StatelessWidget {
  final Widget child;
  final bool animate;
  final Color glowColor;

  const _AnimatedGuestEntry({
    super.key,
    required this.child,
    required this.animate,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final glow = 1 - value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - value)),
            child: Transform.scale(
              scale: 0.94 + (0.06 * value),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.45 * glow),
                      blurRadius: 28 * glow,
                      spreadRadius: 3 * glow,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IncomingRequestPopup extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const _IncomingRequestPopup({
    required this.request,
    required this.onReject,
    required this.onAccept,
  });

  String _title() {
    switch (request.type) {
      case RequestType.truth:
        return '${request.targetUserName} te ha invitado a jugar verdad o reto';
      case RequestType.dare:
        return '${request.targetUserName} te ha invitado a jugar verdad o reto';
      case RequestType.messageRequest:
        return '${request.targetUserName} quiere hablar contigo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF171727),
              Color(0xFF10101A),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF9C4DFF),
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B3DFF).withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _title(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF18183A),
                    Color(0xFF101028),
                  ],
                ),
                border: Border.all(
                  color: Color(0xFF9C4DFF),
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 72,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Acepta o rechaza antes de seguir viendo los invitados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DecisionButton(
                  color: const Color(0xFFFF3B5C),
                  icon: Icons.close_rounded,
                  onTap: onReject,
                ),
                _DecisionButton(
                  color: const Color(0xFF66D63E),
                  icon: Icons.check_rounded,
                  onTap: onAccept,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedRequestResponsePopup extends StatefulWidget {
  final RequestModel request;
  final VoidCallback onBack;
  final ValueChanged<String> onSendResponse;

  const _AcceptedRequestResponsePopup({
    required this.request,
    required this.onBack,
    required this.onSendResponse,
  });

  @override
  State<_AcceptedRequestResponsePopup> createState() =>
      _AcceptedRequestResponsePopupState();
}

class _AcceptedRequestResponsePopupState
    extends State<_AcceptedRequestResponsePopup> {
  final TextEditingController _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _responseController.text.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF171727),
              Color(0xFF10101A),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF9C4DFF),
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B3DFF).withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1B2C4B),
                    border: Border.all(
                      color: const Color(0xFF52A9FF),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF52A9FF),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.targetUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF9C4DFF),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFEAB308),
                  width: 2,
                ),
              ),
              child: Text(
                widget.request.content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFEAB308),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF101018),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.3,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _responseController,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (canSend) {
                          widget.onSendResponse(
                            _responseController.text.trim(),
                          );
                        }
                      },
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Responde a ${widget.request.targetUserName}',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: canSend
                        ? () => widget.onSendResponse(
                              _responseController.text.trim(),
                            )
                        : null,
                    child: Icon(
                      Icons.send_rounded,
                      color: canSend
                          ? const Color(0xFF52A9FF)
                          : const Color(0xFF52A9FF).withValues(alpha: 0.35),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_DecisionButton> createState() => _DecisionButtonState();
}

class _DecisionButtonState extends State<_DecisionButton> {
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
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _pressed ? 0.45 : 0.25),
              blurRadius: _pressed ? 18 : 12,
              spreadRadius: _pressed ? 1.5 : 0.5,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String saludo;
  final String codigoSala;
  final VoidCallback onQrTap;

  const _TopHeader({
    required this.saludo,
    required this.codigoSala,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saludo,
                style: const TextStyle(
                  color: Color(0xFFD78BFF),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                codigoSala,
                style: const TextStyle(
                  color: Color(0xFF52A9FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _QrButton(onTap: onQrTap),
      ],
    );
  }
}

class _QrButton extends StatefulWidget {
  final VoidCallback onTap;

  const _QrButton({required this.onTap});

  @override
  State<_QrButton> createState() => _QrButtonState();
}

class _QrButtonState extends State<_QrButton> {
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF7E2BE8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF8B3DFF).withValues(alpha: _pressed ? 0.45 : 0.18),
              blurRadius: _pressed ? 20 : 12,
              spreadRadius: _pressed ? 1.2 : 0.4,
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_2_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final String name;
  final int age;
  final String? foto;
  final Color statusColor;
  final String? pendingLabel;
  final bool hasRequestSent;
  final VoidCallback onTap;
  final Color? pendingLabelColor;

  const _GuestCard({
    required this.name,
    required this.age,
    required this.foto,
    required this.statusColor,
    required this.onTap,
    required this.hasRequestSent,
    this.pendingLabel,
    this.pendingLabelColor,
  });

  ImageProvider? _profileImage() {
    if (foto == null || foto!.trim().isEmpty) return null;

    try {
      var cleanBase64 = foto!.trim();

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
    final image = _profileImage();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151525),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasRequestSent
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFD78BFF).withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            hasRequestSent
                ? _StaticProfilePhoto(
                    image: image,
                    statusColor: statusColor,
                  )
                : _BlinkingProfilePhoto(
                    image: image,
                    statusColor: statusColor,
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name, $age',
                    style: TextStyle(
                      color: hasRequestSent
                          ? Colors.white.withValues(alpha: 0.62)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pendingLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      pendingLabel!,
                      style: TextStyle(
                        color: pendingLabelColor ?? const Color(0xFFEAB308),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            hasRequestSent
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 24,
                  )
                : _GlowingArrow(color: const Color(0xFF9C4DFF)),
          ],
        ),
      ),
    );
  }
}

class _BlinkingProfilePhoto extends StatefulWidget {
  final ImageProvider? image;
  final Color statusColor;

  const _BlinkingProfilePhoto({
    required this.image,
    required this.statusColor,
  });

  @override
  State<_BlinkingProfilePhoto> createState() => _BlinkingProfilePhotoState();
}

class _BlinkingProfilePhotoState extends State<_BlinkingProfilePhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(2.4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.statusColor.withValues(alpha: 0.65 + (_glow.value * 0.35)),
              width: 2.6,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.statusColor.withValues(alpha: 0.45 * _glow.value),
                blurRadius: 18 * _glow.value,
                spreadRadius: 1.4 * _glow.value,
              ),
            ],
          ),
          child: _PhotoCircle(image: widget.image),
        );
      },
    );
  }
}

class _StaticProfilePhoto extends StatelessWidget {
  final ImageProvider? image;
  final Color statusColor;

  const _StaticProfilePhoto({
    required this.image,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 2.2,
        ),
      ),
      child: _PhotoCircle(image: image),
    );
  }
}

class _PhotoCircle extends StatelessWidget {
  final ImageProvider? image;

  const _PhotoCircle({
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: image != null
          ? Image(
              image: image!,
              width: 52,
              height: 52,
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
    );
  }
}

class _GlowingArrow extends StatefulWidget {
  final Color color;

  const _GlowingArrow({
    required this.color,
  });

  @override
  State<_GlowingArrow> createState() => _GlowingArrowState();
}

class _GlowingArrowState extends State<_GlowingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35 * _glow.value),
                blurRadius: 14 * _glow.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: widget.color.withValues(alpha: 0.75 + (_glow.value * 0.25)),
            size: 28,
          ),
        );
      },
    );
  }
}