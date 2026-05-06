import 'package:flutter/material.dart';
import 'chat_preview_state.dart';

class ChatModel {
  final String id;
  final String otherUserId;
  final String userName;
  final String? foto;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final Color statusColor;
  final ChatPreviewState previewState;

  const ChatModel({
    required this.id,
    required this.otherUserId,
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.statusColor,
    this.foto,
    this.previewState = ChatPreviewState.normal,
  });

  ChatModel copyWith({
    String? id,
    String? otherUserId,
    String? userName,
    String? foto,
    String? lastMessage,
    String? time,
    int? unreadCount,
    Color? statusColor,
    ChatPreviewState? previewState,
  }) {
    return ChatModel(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      userName: userName ?? this.userName,
      foto: foto ?? this.foto,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      statusColor: statusColor ?? this.statusColor,
      previewState: previewState ?? this.previewState,
    );
  }
}