import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'dart:math';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  final List<UserModel> _users = [];
  final List<FriendRequest> _friendRequests = [];
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  // Danh sách bạn bè của người dùng hiện tại
  List<UserModel> get friends {
    if (_currentUser == null) return [];
    return _users.where((user) => 
      _currentUser!.friendIds.contains(user.id)).toList();
  }

  // Danh sách yêu cầu kết bạn đến người dùng hiện tại
  List<FriendRequest> get incomingRequests {
    if (_currentUser == null) return [];
    return _friendRequests.where((request) => 
      request.receiverId == _currentUser!.id && 
      request.status == 'pending').toList();
  }

  // Danh sách yêu cầu kết bạn từ người dùng hiện tại
  List<FriendRequest> get outgoingRequests {
    if (_currentUser == null) return [];
    return _friendRequests.where((request) => 
      request.senderId == _currentUser!.id && 
      request.status == 'pending').toList();
  }

  // Lấy thông tin người dùng từ UserID
  UserModel? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Khởi tạo dữ liệu người dùng (mô phỏng)
  Future<void> initUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Giả lập dữ liệu cho demo
      await Future.delayed(const Duration(seconds: 1));
      
      // Người dùng hiện tại
      _currentUser = UserModel(
        id: "user123",
        name: "Nguyễn Văn A",
        email: "nguyenvana@email.com",
        avatarUrl: "assets/avatar.jpg",
        daysUsed: 23,
        achievements: 17,
        efficiency: 85,
      );

      // Thêm một số người dùng mẫu
      _users.addAll([
        _currentUser!,
        UserModel(
          id: "user456",
          name: "Trần Thị B",
          email: "tranthib@email.com",
          avatarUrl: "assets/avatar.jpg",
          daysUsed: 45,
          achievements: 23,
          efficiency: 92,
        ),
        UserModel(
          id: "user789",
          name: "Lê Văn C",
          email: "levanc@email.com",
          avatarUrl: "assets/avatar.jpg",
          daysUsed: 30,
          achievements: 15,
          efficiency: 78,
        ),
        UserModel(
          id: "user101",
          name: "Phạm Thị D",
          email: "phamthid@email.com",
          avatarUrl: "assets/avatar.jpg",
          daysUsed: 60,
          achievements: 35,
          efficiency: 95,
        ),
        UserModel(
          id: "user202",
          name: "Hoàng Văn E",
          email: "hoangvane@email.com",
          avatarUrl: "assets/avatar.jpg",
          daysUsed: 15,
          achievements: 8,
          efficiency: 70,
        ),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Tìm kiếm người dùng theo ID
  Future<UserModel?> searchUserById(String userId) async {
    if (userId.isEmpty) {
      return null;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Mô phỏng tìm kiếm trên server
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Kiểm tra xem người dùng đã có trong danh sách hay chưa
      final existingUser = _users.where((user) => user.id == userId).toList();
      if (existingUser.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return existingUser.first;
      }
      
      // Kiểm tra định dạng ID hợp lệ (giả sử ID bắt đầu bằng "user")
      if (!userId.startsWith('user')) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Tạo người dùng mới nếu ID hợp lệ
      final newUser = UserModel(
        id: userId,
        name: "Người dùng ${Random().nextInt(1000)}",
        email: "user$userId@email.com",
        avatarUrl: "assets/avatar.jpg",
        daysUsed: Random().nextInt(60) + 1,
        achievements: Random().nextInt(30) + 1,
        efficiency: (60 + Random().nextInt(35)).toDouble(),
        friendIds: const [],
      );
      
      // Thêm người dùng mới vào danh sách
      _users.add(newUser);
      
      _isLoading = false;
      notifyListeners();
      return newUser;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Gửi yêu cầu kết bạn
  Future<bool> sendFriendRequest(String userId) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Mô phỏng gửi yêu cầu trên server
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Kiểm tra xem đã gửi lời mời chưa
      bool alreadySent = _friendRequests.any(
        (request) => 
          request.senderId == _currentUser!.id && 
          request.receiverId == userId &&
          request.status == 'pending'
      );
      
      // Nếu đã kết bạn hoặc đã gửi lời mời, không làm gì
      if (_currentUser!.friendIds.contains(userId) || alreadySent) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Tạo yêu cầu kết bạn mới
      final newRequest = FriendRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        senderId: _currentUser!.id, 
        receiverId: userId, 
        createdAt: DateTime.now(), 
        status: 'pending'
      );
      
      _friendRequests.add(newRequest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Chấp nhận lời mời kết bạn
  Future<bool> acceptFriendRequest(String requestId) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Mô phỏng xử lý trên server
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Tìm yêu cầu kết bạn
      int index = _friendRequests.indexWhere((req) => req.id == requestId);
      if (index == -1) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Cập nhật trạng thái yêu cầu
      final request = _friendRequests[index];
      _friendRequests[index] = request.copyWith(status: 'accepted');
      
      // Cập nhật danh sách bạn bè của người gửi và người nhận
      int senderIndex = _users.indexWhere((user) => user.id == request.senderId);
      int receiverIndex = _users.indexWhere((user) => user.id == request.receiverId);
      
      if (senderIndex != -1 && receiverIndex != -1) {
        // Thêm ID người nhận vào danh sách bạn bè của người gửi
        final sender = _users[senderIndex];
        List<String> senderFriends = List.from(sender.friendIds);
        if (!senderFriends.contains(request.receiverId)) {
          senderFriends.add(request.receiverId);
        }
        _users[senderIndex] = sender.copyWith(friendIds: senderFriends);
        
        // Thêm ID người gửi vào danh sách bạn bè của người nhận
        final receiver = _users[receiverIndex];
        List<String> receiverFriends = List.from(receiver.friendIds);
        if (!receiverFriends.contains(request.senderId)) {
          receiverFriends.add(request.senderId);
        }
        _users[receiverIndex] = receiver.copyWith(friendIds: receiverFriends);
        
        // Cập nhật currentUser nếu là một trong hai bên
        if (_currentUser!.id == sender.id) {
          _currentUser = _users[senderIndex];
        } else if (_currentUser!.id == receiver.id) {
          _currentUser = _users[receiverIndex];
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Từ chối lời mời kết bạn
  Future<bool> rejectFriendRequest(String requestId) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Mô phỏng xử lý trên server
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Tìm yêu cầu kết bạn
      int index = _friendRequests.indexWhere((req) => req.id == requestId);
      if (index == -1) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Cập nhật trạng thái yêu cầu
      final request = _friendRequests[index];
      _friendRequests[index] = request.copyWith(status: 'rejected');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Hủy kết bạn
  Future<bool> removeFriend(String friendId) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Mô phỏng xử lý trên server
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Tìm vị trí của người dùng hiện tại và bạn bè
      int currentUserIndex = _users.indexWhere((user) => user.id == _currentUser!.id);
      int friendIndex = _users.indexWhere((user) => user.id == friendId);
      
      if (currentUserIndex != -1 && friendIndex != -1) {
        // Cập nhật danh sách bạn bè của người dùng hiện tại
        final user = _users[currentUserIndex];
        List<String> userFriends = List.from(user.friendIds);
        userFriends.remove(friendId);
        _users[currentUserIndex] = user.copyWith(friendIds: userFriends);
        
        // Cập nhật danh sách bạn bè của bạn bè
        final friend = _users[friendIndex];
        List<String> friendFriends = List.from(friend.friendIds);
        friendFriends.remove(_currentUser!.id);
        _users[friendIndex] = friend.copyWith(friendIds: friendFriends);
        
        // Cập nhật currentUser
        _currentUser = _users[currentUserIndex];
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}