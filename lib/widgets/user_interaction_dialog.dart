import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';

class DialogRequestResult {
  final String targetUserId;
  final String targetUserName;
  final RequestType type;
  final String content;

  const DialogRequestResult({
    required this.targetUserId,
    required this.targetUserName,
    required this.type,
    required this.content,
  });
}

class UserInteractionDialog extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final int targetUserAge;
  final Color statusColor;
  final String? targetUserFoto;

  const UserInteractionDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserAge,
    required this.statusColor,
    this.targetUserFoto,
  });

  @override
  State<UserInteractionDialog> createState() => _UserInteractionDialogState();
}

class _UserInteractionDialogState extends State<UserInteractionDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _expandedTruthOrDare = false;
  bool _loadingVerdadReto = true;

  String? _verdadBackend;
  String? _retoBackend;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargarVerdadReto();
  }

  String _cleanBase64(String value) {
    if (value.contains(',')) {
      return value.split(',').last;
    }
    return value;
  }

  ImageProvider? _profileImage() {
    final foto = widget.targetUserFoto;

    if (foto == null || foto.trim().isEmpty) {
      return null;
    }

    try {
      return MemoryImage(base64Decode(_cleanBase64(foto.trim())));
    } catch (_) {
      return null;
    }
  }

  Future<void> _showBigAvatar() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BigAvatarDialog(
        name: widget.targetUserName,
        age: widget.targetUserAge,
        statusColor: widget.statusColor,
        foto: widget.targetUserFoto,
      ),
    );
  }

  Future<void> _cargarVerdadReto() async {
    try {
      final data = await ApiService.getVerdadRetoRandom();

      if (!mounted) return;

      setState(() {
        _verdadBackend = data.verdad;
        _retoBackend = data.reto;
        _loadingVerdadReto = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _verdadBackend = '¿Qué pensaste al verme?';
        _retoBackend = 'Te reto a decirme algo sincero.';
        _loadingVerdadReto = false;
      });
    }
  }

  void _sendTruth() {
    final verdad = _verdadBackend?.trim();
    if (verdad == null || verdad.isEmpty) return;

    Navigator.pop(
      context,
      DialogRequestResult(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
        type: RequestType.truth,
        content: verdad,
      ),
    );
  }

  void _sendDare() {
    final reto = _retoBackend?.trim();
    if (reto == null || reto.isEmpty) return;

    Navigator.pop(
      context,
      DialogRequestResult(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
        type: RequestType.dare,
        content: reto,
      ),
    );
  }

  void _sendMessageRequest() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    Navigator.pop(
      context,
      DialogRequestResult(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
        type: RequestType.messageRequest,
        content: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _profileImage();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
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
            width: 2.6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B3DFF).withValues(alpha: 0.18),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.targetUserName}, ${widget.targetUserAge}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showBigAvatar,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.statusColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.statusColor.withValues(alpha: 0.22),
                      blurRadius: 12,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: image != null
                      ? Image(
                          image: image,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Escoge cuál enviarle a ${widget.targetUserName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (!_expandedTruthOrDare)
              _BigChoiceButton(
                label: 'Verdad o Reto',
                color: const Color(0xFFEAB308),
                onTap: () {
                  setState(() {
                    _expandedTruthOrDare = true;
                  });
                },
              )
            else
              Column(
                children: [
                  if (_loadingVerdadReto)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(
                        color: Color(0xFF9C4DFF),
                      ),
                    )
                  else ...[
                    _QuestionChoiceCard(
                      title: 'Verdad',
                      color: const Color(0xFFEAB308),
                      text: _verdadBackend ?? '',
                      onTap: _sendTruth,
                    ),
                    const SizedBox(height: 10),
                    _QuestionChoiceCard(
                      title: 'Reto',
                      color: const Color(0xFFEAB308),
                      text: _retoBackend ?? '',
                      onTap: _sendDare,
                    ),
                  ],
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedTruthOrDare = false;
                      });
                    },
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
                ],
              ),
            const SizedBox(height: 18),
            _MessageRequestBar(
              controller: _messageController,
              targetName: widget.targetUserName,
              onSend: _sendMessageRequest,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigChoiceButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigChoiceButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_BigChoiceButton> createState() => _BigChoiceButtonState();
}

class _BigChoiceButtonState extends State<_BigChoiceButton> {
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
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFF2A220A).withValues(alpha: 0.20),
          border: Border.all(
            color: widget.color,
            width: _pressed ? 2.6 : 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.20),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _QuestionChoiceCard extends StatefulWidget {
  final String title;
  final Color color;
  final String text;
  final VoidCallback onTap;

  const _QuestionChoiceCard({
    required this.title,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  State<_QuestionChoiceCard> createState() => _QuestionChoiceCardState();
}

class _QuestionChoiceCardState extends State<_QuestionChoiceCard> {
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
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF181818),
          border: Border.all(
            color: widget.color,
            width: _pressed ? 2.6 : 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: widget.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageRequestBar extends StatefulWidget {
  final TextEditingController controller;
  final String targetName;
  final VoidCallback onSend;

  const _MessageRequestBar({
    required this.controller,
    required this.targetName,
    required this.onSend,
  });

  @override
  State<_MessageRequestBar> createState() => _MessageRequestBarState();
}

class _MessageRequestBarState extends State<_MessageRequestBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.controller.text.trim().isNotEmpty;

    return Container(
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
              controller: widget.controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje a ${widget.targetName}',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: enabled ? widget.onSend : null,
            child: Icon(
              Icons.send_rounded,
              color: enabled
                  ? const Color(0xFF52A9FF)
                  : const Color(0xFF52A9FF).withValues(alpha: 0.35),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigAvatarDialog extends StatelessWidget {
  final String name;
  final int age;
  final Color statusColor;
  final String? foto;

  const _BigAvatarDialog({
    required this.name,
    required this.age,
    required this.statusColor,
    this.foto,
  });

  String _cleanBase64(String value) {
    if (value.contains(',')) {
      return value.split(',').last;
    }
    return value;
  }

  ImageProvider? _profileImage() {
    if (foto == null || foto!.trim().isEmpty) {
      return null;
    }

    try {
      return MemoryImage(base64Decode(_cleanBase64(foto!.trim())));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _profileImage();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
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
            width: 2.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$name, $age',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF18183A),
                    Color(0xFF101028),
                  ],
                ),
                border: Border.all(
                  color: statusColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.28),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: image != null
                    ? Image(
                        image: image,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 110,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              image != null
                  ? 'Vista ampliada del perfil'
                  : 'Este usuario no tiene foto de perfil',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}