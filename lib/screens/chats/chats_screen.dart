import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_model.dart';
import '../../models/chat_preview_state.dart';
import '../../state/app_state.dart';
import '../../widgets/voo_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import 'chat_conversation_screen.dart';
import '../retos/retos_screen.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await context.read<AppState>().iniciarSignalR();
      await context.read<AppState>().cargarChats();
    });
  }

  Color _previewColor(ChatPreviewState state, int unreadCount) {
    if (unreadCount > 0) return const Color(0xFF52A9FF);

    switch (state) {
      case ChatPreviewState.normal:
        return Colors.white54;
      case ChatPreviewState.missionBusy:
        return const Color(0xFFFF8FB1);
      case ChatPreviewState.answeredRequest:
        return const Color(0xFF52A9FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isHost = appState.isHost;
    final List<ChatModel> chats = appState.dynamicChats;

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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Es ahora o Nunca!',
                  style: TextStyle(
                    color: Color(0xFFD78BFF),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appState.roomCode ?? '---',
                  style: const TextStyle(
                    color: Color(0xFF52A9FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tus chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: appState.loadingChats && chats.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9C4DFF),
                          ),
                        )
                      : chats.isEmpty
                          ? Center(
                              child: Text(
                                'Todavía no tienes conversaciones',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: chats.length,
                              separatorBuilder: (_, _) => Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              itemBuilder: (context, index) {
                                final chat = chats[index];

                                return _ChatCard(
                                  chat: chat,
                                  isHost: isHost,
                                  previewColor: _previewColor(
                                    chat.previewState,
                                    chat.unreadCount,
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 10),
                VooBottomNavBar(
                  currentIndex: 1,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                      );
                    } else if (index == 1) {
                      return;
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
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final ChatModel chat;
  final bool isHost;
  final Color previewColor;

  const _ChatCard({
    required this.chat,
    required this.isHost,
    required this.previewColor,
  });

  ImageProvider? _profileImage() {
    final foto = chat.foto;
    if (foto == null || foto.trim().isEmpty) return null;

    try {
      var cleanBase64 = foto.trim();

      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      cleanBase64 = cleanBase64
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .replaceAll(' ', '')
          .replaceAll('"', '');

      return MemoryImage(base64Decode(cleanBase64));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _profileImage();

    final lastMessage = chat.lastMessage.trim().isEmpty
        ? 'Todavía no hay mensajes'
        : chat.lastMessage.trim();

    return GestureDetector(
      onTap: () {
        if (chat.previewState == ChatPreviewState.missionBusy) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${chat.userName} está en una misión ahora mismo ¡intenta con otro!',
              ),
            ),
          );
          return;
        }

        if (chat.unreadCount > 0) {
          context.read<AppState>().markAnsweredRequestAsSeen(chat.id);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              isHost: isHost,
              chatId: chat.id,
              targetUserId: chat.otherUserId,
              chatName: chat.userName,
              chatFoto: chat.foto,
              statusColor: chat.statusColor,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: chat.statusColor,
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
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.userName,
                    style: TextStyle(
                      color: chat.unreadCount > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.88),
                      fontSize: 15,
                      fontWeight: chat.unreadCount > 0
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: previewColor,
                      fontSize: 13,
                      fontWeight: chat.unreadCount > 0
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (chat.time.isNotEmpty)
              Text(
                chat.time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            if (chat.unreadCount > 0)
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFF52A9FF),
                child: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}