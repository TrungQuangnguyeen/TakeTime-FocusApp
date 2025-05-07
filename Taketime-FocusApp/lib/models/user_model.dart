class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int daysUsed;
  final int achievements;
  final double efficiency;
  final List<String> friendIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.daysUsed,
    required this.achievements,
    required this.efficiency,
    this.friendIds = const [],
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? daysUsed,
    int? achievements,
    double? efficiency,
    List<String>? friendIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      daysUsed: daysUsed ?? this.daysUsed,
      achievements: achievements ?? this.achievements,
      efficiency: efficiency ?? this.efficiency,
      friendIds: friendIds ?? this.friendIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'daysUsed': daysUsed,
      'achievements': achievements,
      'efficiency': efficiency,
      'friendIds': friendIds,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String,
      daysUsed: json['daysUsed'] as int,
      achievements: json['achievements'] as int,
      efficiency: json['efficiency'] as double,
      friendIds: (json['friendIds'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  final String status; // pending, accepted, rejected

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    required this.status,
  });

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    DateTime? createdAt,
    String? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
    );
  }
}