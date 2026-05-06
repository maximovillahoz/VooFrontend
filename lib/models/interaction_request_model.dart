enum InteractionType {
  truth,
  dare,
  messageRequest,
}

class InteractionRequestModel {
  final String targetUserId;
  final String targetUserName;
  final InteractionType type;
  final String content;

  const InteractionRequestModel({
    required this.targetUserId,
    required this.targetUserName,
    required this.type,
    required this.content,
  });
}