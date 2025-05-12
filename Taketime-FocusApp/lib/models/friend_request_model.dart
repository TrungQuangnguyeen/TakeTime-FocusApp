class FriendRequest {
  final String friendshipId;
  final String requesterId;
  final String receiverId;
  final String status;

  FriendRequest({
    required this.friendshipId,
    required this.requesterId,
    required this.receiverId,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      friendshipId: json['friendship_id'] as String? ?? json['friendshipId'] as String, // Handles both snake_case and camelCase
      requesterId: json['requester_id'] as String? ?? json['requesterId'] as String, // Handles both snake_case and camelCase
      receiverId: json['receiver_id'] as String? ?? json['receiverId'] as String, // Handles both snake_case and camelCase
      status: json['relationship_status'] as String? ?? json['status'] as String, // Handles both snake_case (from DB) and camelCase
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendshipId': friendshipId,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status,
    };
  }
}
