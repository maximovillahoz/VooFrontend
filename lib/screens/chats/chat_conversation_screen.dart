import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/message_model.dart';
import '../../state/app_state.dart';
import 'dart:convert';

class ChatConversationScreen extends StatefulWidget {
  final bool isHost;
  final String chatId;
  final String targetUserId;
  final String chatName;
  final String? chatFoto;
  final Color statusColor;

  const ChatConversationScreen({
    super.key,
    required this.isHost,
    required this.chatId,
    required this.chatName,
    required this.statusColor,
    required this.targetUserId,
    required this.chatFoto,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<AppState>().setActiveChat(widget.chatId);

      await context.read<AppState>().cargarMensajesChat(widget.chatId);
      context.read<AppState>().marcarChatComoLeidoLocal(widget.chatId);

      _jumpToBottom();
      _messageFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _messageFocusNode.dispose();
    context.read<AppState>().setActiveChat(null);
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow = !_isNearBottom();

    if (shouldShow != _showScrollToBottomButton && mounted) {
      setState(() {
        _showScrollToBottomButton = shouldShow;
      });
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;

    return distanceToBottom <= 80;
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _animateToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final shouldStickToBottom = _isNearBottom();

    await context.read<AppState>().sendChatMessage(
          chatId: widget.chatId,
          targetUserId: widget.targetUserId,
          text: text,
          isMine: true,
        );

    _messageController.clear();
    _animateToBottom();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldStickToBottom) {
        _animateToBottom();
      } else {
        _handleScroll();
      }

      if (mounted) {
        _messageFocusNode.requestFocus();
      }
    });
  }

  ImageProvider? _profileImage() {
    final foto = widget.chatFoto;

    if (foto == null || foto.trim().isEmpty) return null;

    try {
      var cleanBase64 = foto.trim();

      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      return MemoryImage(base64Decode(cleanBase64));
    } catch (_) {
      return null;
    }
  }

  void _showProfileImage() {
    final image = _profileImage();
    if (image == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(22),
            child: Center(
              child: Hero(
                tag: 'chat-photo-${widget.chatId}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image(
                    image: image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<AppState>().getMessagesForChat(widget.chatId);
    final image = _profileImage();

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    _BackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showProfileImage,
                      child: Hero(
                        tag: 'chat-photo-${widget.chatId}',
                        child: Container(
                          width: 46,
                          height: 46,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.statusColor,
                              width: 2.4,
                            ),
                          ),
                          child: ClipOval(
                            child: image != null
                                ? Image(
                                    image: image,
                                    width: 46,
                                    height: 46,
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
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'En sala',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.58),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 18),
                            child: Center(
                              child: _ConversationBadge(
                                text: 'Hoy',
                              ),
                            ),
                          );
                        }

                        final MessageModel message = messages[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MessageBubble(message: message),
                        );
                      },
                    ),
                    Positioned(
                      right: 16,
                      bottom: 14,
                      child: AnimatedScale(
                        scale: _showScrollToBottomButton ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedOpacity(
                          opacity: _showScrollToBottomButton ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: _ScrollToBottomButton(
                            onTap: _animateToBottom,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MessageInput(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        onSubmitted: (_) {
                          _sendMessage();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SendButton(
                      onTap: () {
                        _sendMessage();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationBadge extends StatelessWidget {
  final String text;

  const _ConversationBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF9C4DFF).withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isMine ? Alignment.centerRight : Alignment.centerLeft;

    final background = message.isMine
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A28),
              Color(0xFF11111B),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B1452),
              Color(0xFF7E2BE8),
            ],
          );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(message.isMine ? 20 : 6),
              bottomRight: Radius.circular(message.isMine ? 6 : 20),
            ),
            border: Border.all(
              color: message.isMine
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFF9C4DFF).withValues(alpha: 0.65),
              width: 1.1,
            ),
            boxShadow: !message.isMine
                ? [
                    BoxShadow(
                      color: const Color(0xFF9C4DFF).withValues(alpha: 0.20),
                      blurRadius: 12,
                      spreadRadius: 0.5,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message.time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
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
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF9C4DFF).withValues(alpha: 0.20),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.send,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Escribe un mensaje',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
            ),
            filled: true,
            fillColor: const Color(0xFF151525),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: const Color(0xFF9C4DFF).withValues(alpha: 0.32),
                width: 1.4,
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

class _SendButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SendButton({
    required this.onTap,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.38),
                    blurRadius: 16,
                    spreadRadius: 1.2,
                  ),
                ]
              : [],
        ),
        child: const Icon(
          Icons.send_rounded,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ScrollToBottomButton({
    required this.onTap,
  });

  @override
  State<_ScrollToBottomButton> createState() => _ScrollToBottomButtonState();
}

class _ScrollToBottomButtonState extends State<_ScrollToBottomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF22C55E);

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
          color: const Color(0xAA151515),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.75),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _pressed ? 0.28 : 0.14),
              blurRadius: _pressed ? 16 : 10,
              spreadRadius: _pressed ? 1.2 : 0.3,
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: color.withValues(alpha: 0.95),
          size: 28,
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButton({
    required this.onTap,
  });

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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
              color: const Color(0xFF8B3DFF).withValues(alpha: _pressed ? 0.45 : 0.18),
              blurRadius: _pressed ? 20 : 12,
              spreadRadius: _pressed ? 1.2 : 0.4,
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