enum RequestType {
  truth,
  dare,
  messageRequest,
}

enum RequestStatus {
  pending,
  accepted,
  rejected,
  answered,
}

class RequestModel {
  final String id;
  final String targetUserId;
  final String targetUserName;
  final RequestType type;
  final String content;
  final RequestStatus status;
  final DateTime createdAt;

  const RequestModel({
    required this.id,
    required this.targetUserId,
    required this.targetUserName,
    required this.type,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  RequestModel copyWith({
    String? id,
    String? targetUserId,
    String? targetUserName,
    RequestType? type,
    String? content,
    RequestStatus? status,
    DateTime? createdAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}