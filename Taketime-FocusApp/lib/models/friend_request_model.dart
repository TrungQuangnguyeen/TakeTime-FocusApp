class FriendRequest {
  final String friendshipId;
  final String requesterId;
  final String receiverId;
  final String status;
  final String? requesterName;
  final String? requesterEmail;
  final DateTime requestedAt;

  FriendRequest({
    required this.friendshipId,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.requesterName,
    this.requesterEmail,
    required this.requestedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      friendshipId: json['friendship_id'] ?? json['friendshipId'],
      requesterId: json['requester_id'] ?? json['requesterId'],
      receiverId: json['receiver_id'] ?? json['receiverId'],
      status: json['relationship_status'] ?? json['status'],
      requesterName: json['requesterName'],
      requesterEmail: json['requesterEmail'],
      requestedAt: DateTime.parse(json['requested_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendshipId': friendshipId,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}
