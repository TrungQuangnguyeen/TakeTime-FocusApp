class UserModel {
  final String id;
  final String username;
  final String email;
  String? avatarUrl;
  String? friendshipId; // Added for storing friendship ID when user is a friend
  final String?
  friendshipStatus; // Added for storing friendship status from search results
  String? projectId; // Thêm trường này để lưu projectId của user

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.friendshipId,
    this.friendshipStatus, // Added
    this.projectId, // Thêm trường này
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? friendshipId,
    String? friendshipStatus, // Added
    String? projectId, // Thêm trường này
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      friendshipId: friendshipId ?? this.friendshipId,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus, // Added
      projectId: projectId ?? this.projectId, // Thêm trường này
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely get a string value for a list of possible keys
    String? getString(List<String> keys) {
      for (String key in keys) {
        if (json.containsKey(key) && json[key] != null && json[key] is String) {
          return json[key] as String;
        }
      }
      return null;
    }

    final String parsedId =
        getString(['user_id', 'id', 'userId']) ??
        ''; // Fallback to empty string if all null, but ID should be present
    final String parsedUsername =
        getString(['full_name', 'username', 'name']) ?? ''; // Fallback
    final String parsedEmail = getString(['email']) ?? ''; // Fallback
    final String? parsedAvatarUrl = getString([
      'avatar_url',
      'avatarUrl',
      'picture',
    ]);
    final String? parsedFriendshipId = getString([
      'friendship_id',
      'friendshipId',
    ]);
    final String? parsedFriendshipStatus = getString([
      'friendshipStatus',
      'friendship_status',
    ]); // Added
    final String? parsedProjectId = getString([
      'projectId',
      'project_id',
    ]); // Thêm trường này

    // ignore: avoid_print
    print("[UserModel.fromJson] Parsing JSON: $json");
    // ignore: avoid_print
    print(
      "[UserModel.fromJson] -> Extracted id: '$parsedId' (from user_id, id, userId)",
    );
    // ignore: avoid_print
    print(
      "[UserModel.fromJson] -> Extracted username: '$parsedUsername' (from full_name, username, name)",
    );
    // ignore: avoid_print
    print("[UserModel.fromJson] -> Extracted email: '$parsedEmail'");
    // ignore: avoid_print
    print("[UserModel.fromJson] -> Extracted avatarUrl: '$parsedAvatarUrl'");
    // ignore: avoid_print
    print(
      "[UserModel.fromJson] -> Extracted friendshipId: '$parsedFriendshipId'",
    );
    // ignore: avoid_print
    print(
      "[UserModel.fromJson] -> Extracted friendshipStatus: '$parsedFriendshipStatus'",
    ); // Added
    // ignore: avoid_print
    print(
      "[UserModel.fromJson] -> Extracted projectId: '$parsedProjectId'",
    ); // Thêm log

    if (parsedId.isEmpty) {
      // ignore: avoid_print
      print(
        "[UserModel.fromJson] CRITICAL ERROR: User ID is empty after parsing. Original JSON: $json",
      );
      // Tùy thuộc vào mức độ nghiêm ngặt bạn muốn, bạn có thể ném ra ngoại lệ
      // throw Exception("User ID is missing or null in UserModel.fromJson");
    }
    if (parsedUsername.isEmpty) {
      // ignore: avoid_print
      print(
        "[UserModel.fromJson] WARNING: Username is empty after parsing. Original JSON: $json",
      );
    }
    if (parsedEmail.isEmpty) {
      // ignore: avoid_print
      print(
        "[UserModel.fromJson] WARNING: Email is empty after parsing. Original JSON: $json",
      );
    }

    return UserModel(
      id: parsedId, // UserModel.id is non-nullable
      username: parsedUsername, // UserModel.username is non-nullable
      email: parsedEmail, // UserModel.email is non-nullable
      avatarUrl: parsedAvatarUrl,
      friendshipId: parsedFriendshipId,
      friendshipStatus: parsedFriendshipStatus, // Added
      projectId: parsedProjectId, // Thêm trường này
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // It's good practice to decide on one casing for sending data if the backend has a preference
      // For now, using a common one, but align with backend if needed for POST/PUT.
      'fullName': username,
      'email': email,
      'avatar_url': avatarUrl,
      'friendshipId': friendshipId,
      'friendshipStatus':
          friendshipStatus, // Added (though primarily for client-side use from search)
      'projectId': projectId, // Thêm trường này (nếu cần gửi đi)
    };
  }
}
