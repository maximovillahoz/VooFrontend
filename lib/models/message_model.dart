class MessageModel {
  final String id;
  final String chatId;
  final String text;
  final bool isMine;
  final String time;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.text,
    required this.isMine,
    required this.time,
  });
}