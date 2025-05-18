import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/friend_request_model.dart'; // Correct import for FriendRequest
import 'package:flutter/foundation.dart' show kIsWeb;

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _friends = []; // Stores list of friends
  List<FriendRequest> _incomingFriendRequests = [];
  List<FriendRequest> _outgoingFriendRequests = [];
  List<FriendRequest> _acceptedFriendships =
      []; // Stores accepted friend requests
  bool _isLoading = false;
  String? _accessToken;
  List<UserModel> _searchedUsers = [];

  final String _baseUrl =
      kIsWeb ? "http://localhost:5220" : "http://10.0.2.2:5220";

  // Getters
  UserModel? get currentUser => _currentUser;
  List<UserModel> get friends => _friends;
  List<FriendRequest> get incomingFriendRequests => _incomingFriendRequests;
  List<FriendRequest> get outgoingFriendRequests => _outgoingFriendRequests;
  List<FriendRequest> get acceptedFriendships =>
      _acceptedFriendships; // Getter for accepted friendships
  bool get isLoading => _isLoading;
  List<UserModel> get searchedUsers => _searchedUsers;
  String get baseUrl => _baseUrl;
  Map<String, String> get headers => _headers;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  void setAuthToken(String? token) {
    _accessToken = token;
    if (token != null) {
      print(
        '[UserProvider] Auth token set. Fetching current user, friends, and friend requests.',
      );
      fetchCurrentUser();
      fetchFriends();
      fetchFriendRequests(); // This will now also populate _acceptedFriendships
    } else {
      print('[UserProvider] Auth token cleared. Clearing user data.');
      _currentUser = null;
      _friends = [];
      _incomingFriendRequests = [];
      _outgoingFriendRequests = [];
      _acceptedFriendships = []; // Clear accepted friendships
      _searchedUsers = [];
    }
    notifyListeners();
  }

  Future<void> fetchCurrentUser() async {
    print('[UserProvider] fetchCurrentUser called.');
    if (_accessToken == null) {
      print(
        '[UserProvider] fetchCurrentUser: _accessToken is null, returning.',
      );
      return;
    }
    print(
      '[UserProvider] Current Access Token being used for /api/users/profile: \\$_accessToken',
    );

    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/profile'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        _currentUser = UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        print(
          'Failed to fetch current user: \\${response.statusCode} \\${response.body}',
        );
        _currentUser = null;
      }
    } catch (e) {
      print('Error fetching current user: \\${e.toString()}');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFriends() async {
    print('[UserProvider] fetchFriends called.'); // Added log
    if (_accessToken == null) {
      print(
        '[UserProvider] fetchFriends: _accessToken is null, returning.',
      ); // Added log
      _friends = [];
      notifyListeners(); // Notify even if token is null to clear list
      return;
    }
    _isLoading = true;
    notifyListeners();
    List<UserModel> successfullyParsedFriends = [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/FriendShip/friends'),
        headers: _headers,
      );

      print('[UserProvider] Fetch Friends Status Code: ${response.statusCode}');
      print(
        '[UserProvider] Fetch Friends Response Body: ${response.body}',
      ); // Uncommented for detailed API response

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        for (var item in data) {
          try {
            // The API /api/FriendShip/friends returns a flat list of user objects
            // No need to look for 'friendUser' or 'friend_user' here.
            // Each 'item' is a friend's data directly.
            // UserModel.fromJson will now handle the different key names (e.g., user_id, full_name)
            // Note: friendshipId might be missing from this endpoint's response.
            successfullyParsedFriends.add(
              UserModel.fromJson(item as Map<String, dynamic>),
            );
          } catch (e) {
            print(
              '[UserProvider] Error parsing individual friend item from /friends: $item, error: $e',
            );
          }
        }
        _friends = successfullyParsedFriends;
        if (data.isNotEmpty && _friends.isEmpty) {
          print(
            '[UserProvider] Warning: API /friends returned friend data, but all items failed to parse.',
          );
        }
      } else {
        print(
          '[UserProvider] Failed to fetch friends: ${response.statusCode} ${response.body}',
        );
        _friends = [];
      }
    } catch (e) {
      print('[UserProvider] Error fetching friends (overall try-catch): $e');
      _friends = [];
    } finally {
      _isLoading = false;
      print(
        '[UserProvider] fetchFriends completed. Parsed ${_friends.length} friends.',
      );
      notifyListeners();
    }
  }

  Future<void> fetchFriendRequests() async {
    print('[UserProvider] fetchFriendRequests called.');
    if (_accessToken == null || _currentUser == null) {
      print(
        '[UserProvider] fetchFriendRequests: _accessToken or _currentUser is null, returning.',
      );
      _incomingFriendRequests = [];
      _outgoingFriendRequests = [];
      _acceptedFriendships = []; // Clear accepted friendships
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    List<FriendRequest> successfullyParsedRequests =
        []; // Temporary list for successfully parsed items
    int previousIncomingCount =
        _incomingFriendRequests.length; // Track previous count

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/FriendShip/requests'),
        headers: _headers,
      );
      print(
        '[UserProvider] Fetch Friend Requests Status Code: ${response.statusCode}',
      );
      print(
        '[UserProvider] Fetch Friend Requests Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        for (var item in data) {
          try {
            successfullyParsedRequests.add(
              FriendRequest.fromJson(item as Map<String, dynamic>),
            );
          } catch (e) {
            print(
              '[UserProvider] Error parsing individual friend request item: $item, error: $e',
            );
            // Skip this item and continue with the next
          }
        }

        _incomingFriendRequests =
            successfullyParsedRequests
                .where(
                  (FriendRequest req) =>
                      req.receiverId == _currentUser!.id &&
                      req.status.toLowerCase() == 'pending',
                )
                .toList();
        _outgoingFriendRequests =
            successfullyParsedRequests
                .where(
                  (FriendRequest req) =>
                      req.requesterId == _currentUser!.id &&
                      req.status.toLowerCase() == 'pending',
                )
                .toList();
        _acceptedFriendships =
            successfullyParsedRequests
                .where(
                  (FriendRequest req) =>
                      req.status == 'accepted' &&
                      (req.requesterId == _currentUser!.id ||
                          req.receiverId == _currentUser!.id),
                )
                .toList();

        // Check if there are new incoming requests
        if (_incomingFriendRequests.length > previousIncomingCount) {
          // Notify listeners that there are new friend requests
          notifyListeners();
        }
      } else {
        print(
          '[UserProvider] Failed to fetch friend requests: ${response.statusCode} ${response.body}',
        );
        _incomingFriendRequests = [];
        _outgoingFriendRequests = [];
        _acceptedFriendships = [];
      }
    } catch (e) {
      print(
        '[UserProvider] Error fetching friend requests (overall try-catch): $e',
      );
      _incomingFriendRequests = [];
      _outgoingFriendRequests = [];
      _acceptedFriendships = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> fetchUserByIdFromApi(String userId) async {
    if (_accessToken == null) return null;
    // This method might be redundant if searchUsersByQuery is flexible enough
    // For now, it assumes searching by ID via the general search endpoint
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/FriendShip/search?query=$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          // Assuming the API returns the exact match first or only for an ID query
          return UserModel.fromJson(data.first as Map<String, dynamic>);
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID from API: $e');
      return null;
    }
  }

  Future<List<UserModel>> searchUsersByQuery(String query) async {
    print(
      '[UserProvider] searchUsersByQuery called with query: "$query"',
    ); // Added log

    if (_accessToken == null) {
      print(
        '[UserProvider] searchUsersByQuery: _accessToken is null. Aborting search.',
      ); // Added log
      _searchedUsers = [];
      notifyListeners();
      return [];
    }
    if (query.isEmpty) {
      print(
        '[UserProvider] searchUsersByQuery: query is empty. Clearing results.',
      ); // Added log
      _searchedUsers = [];
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _searchedUsers = [];
    notifyListeners();
    print(
      '[UserProvider] searchUsersByQuery: Cleared _searchedUsers and notified listeners. _isLoading is true.',
    ); // Added log

    try {
      final encodedQuery = Uri.encodeQueryComponent(
        query,
      ); // Mã hóa query string
      final searchUrl = Uri.parse(
        '$_baseUrl/api/FriendShip/search?query=$encodedQuery',
      );
      print(
        '[UserProvider] searchUsersByQuery: Attempting to call API: $searchUrl',
      ); // Added log

      final response = await http.get(searchUrl, headers: _headers);
      print('[UserProvider] Search Users Status Code: ${response.statusCode}');
      print('[UserProvider] Search Users Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        print(
          '[UserProvider] searchUsersByQuery: Successfully decoded response. Data length: [32m${data.length}[0m',
        ); // Added log

        List<UserModel> parsedUsers = [];
        for (var jsonItem in data) {
          try {
            parsedUsers.add(
              UserModel.fromJson(jsonItem as Map<String, dynamic>),
            );
          } catch (e) {
            print(
              '[UserProvider] searchUsersByQuery: Error parsing user item: $jsonItem. Error: $e',
            ); // Added log for individual parsing error
          }
        }
        _searchedUsers = parsedUsers;
        print(
          '[UserProvider] searchUsersByQuery: Parsed ${_searchedUsers.length} users.',
        ); // Added log
        if (data.isNotEmpty && _searchedUsers.isEmpty) {
          print(
            '[UserProvider] searchUsersByQuery: Warning - API returned data but no users were successfully parsed.',
          );
        }
      } else {
        print(
          '[UserProvider] Failed to search users: ${response.statusCode} ${response.body}',
        );
        _searchedUsers = [];
      }
    } catch (e, stackTrace) {
      // Added stackTrace
      print('[UserProvider] Error searching users (in catch block): $e');
      print('[UserProvider] StackTrace: $stackTrace'); // Added stacktrace log
      _searchedUsers = [];
    } finally {
      _isLoading = false;
      print(
        '[UserProvider] searchUsersByQuery: Completed. _isLoading is false. Searched users count: ${_searchedUsers.length}',
      ); // Added log
      notifyListeners();
    }
    return _searchedUsers;
  }

  Future<bool> sendFriendRequest(String receiverUserId) async {
    if (_accessToken == null || _currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/FriendShip/send'),
        headers: _headers,
        body: jsonEncode(<String, String>{
          'requesterId': _currentUser!.id,
          'receiverId': receiverUserId,
        }),
      );
      print('SendFriendRequest status: ${response.statusCode}');
      print('SendFriendRequest body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFriendRequests();
        success = true;
      }
    } catch (e) {
      print('Error sending friend request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> acceptFriendRequest(String friendshipId) async {
    if (_accessToken == null) return false;
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/FriendShip/respond/accept/$friendshipId'),
        headers: _headers,
        // body: jsonEncode({}), // Empty body if API expects it or no body
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchFriends();
        await fetchFriendRequests();
        success = true;
      } else {
        print(
          'Failed to accept friend request: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error accepting friend request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> rejectFriendRequest(String friendshipId) async {
    if (_accessToken == null) return false;
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/FriendShip/respond/deny/$friendshipId'),
        headers: _headers,
        // body: jsonEncode({}), // Empty body if API expects it or no body
      );
      if (response.statusCode == 200) {
        await fetchFriendRequests(); // Refresh requests
        success = true;
      } else {
        print(
          'Failed to reject friend request: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error rejecting friend request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> removeFriend(String userIdToRemove) async {
    if (_accessToken == null || _currentUser == null) {
      print(
        "[UserProvider] Access token or current user is null. Cannot remove friend.",
      );
      return false;
    }

    FriendRequest? friendshipToRemove;
    try {
      // Find the accepted friendship involving the current user and the user to remove
      friendshipToRemove = _acceptedFriendships.firstWhere(
        (req) =>
            (req.requesterId == _currentUser!.id &&
                req.receiverId == userIdToRemove) ||
            (req.receiverId == _currentUser!.id &&
                req.requesterId == userIdToRemove),
      );
    } catch (e) {
      // This catch block will be hit if no element satisfies the condition.
      print(
        '[UserProvider] No accepted friendship found with user $userIdToRemove in local _acceptedFriendships list. Cannot remove.',
      );
      print(
        '[UserProvider] Current _acceptedFriendships count: ${_acceptedFriendships.length}. Contents:',
      );
      for (var fr in _acceptedFriendships) {
        // PLEASE REPLACE 'status' WITH THE CORRECT FIELD NAME FROM YOUR FriendRequestModel
        // PLEASE REPLACE 'friendshipId' WITH THE CORRECT FIELD NAME FOR THE ID IN YOUR FriendRequestModel
        print(
          '[UserProvider] Accepted Friendship: ID=${fr.friendshipId}, Requester=${fr.requesterId}, Receiver=${fr.receiverId}, Status=${fr.status}',
        );
      }
      return false;
    }

    // PLEASE REPLACE 'friendshipId' WITH THE CORRECT FIELD NAME FOR THE ID IN YOUR FriendRequestModel
    final String actualFriendshipId = friendshipToRemove.friendshipId;

    print(
      '[UserProvider] Attempting to remove friend $userIdToRemove with Friendship ID: $actualFriendshipId',
    );

    _isLoading = true;
    notifyListeners();
    bool success = false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/FriendShip/remove/$actualFriendshipId'),
        headers: _headers,
      );
      print(
        '[UserProvider] Remove Friend API Status Code: ${response.statusCode}',
      );
      print('[UserProvider] Remove Friend API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
          '[UserProvider] Friend with user ID $userIdToRemove (Friendship ID: $actualFriendshipId) removed successfully via API.',
        );
        await fetchFriends();
        await fetchFriendRequests();

        _searchedUsers.removeWhere((user) => user.id == userIdToRemove);
        success = true;
      } else {
        print(
          '[UserProvider] Failed to remove friend from API: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[UserProvider] Error removing friend via API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  // Utility methods
  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  bool hasSentFriendRequestTo(String userId) {
    return _outgoingFriendRequests.any(
      (request) => request.receiverId == userId && request.status == 'Pending',
    );
  }

  bool hasReceivedFriendRequestFrom(String userId) {
    return _incomingFriendRequests.any(
      (request) => request.requesterId == userId && request.status == 'Pending',
    );
  }
}

// Cần đảm bảo UserModel và FriendRequest có factory constructor fromJson
// Ví dụ cho FriendRequest (điều chỉnh cho phù hợp với API response của bạn):
/*
class FriendRequest {
  final String id; // Đây có thể là friendshipId
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  String status; // 'pending', 'accepted', 'rejected'

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    required this.status,
  });

  FriendRequest copyWith({ ... }) { ... } // Giữ lại nếu bạn có

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['friendshipId'] ?? json['id'], // Kiểm tra key API trả về
      senderId: json['requesterId'] ?? json['senderId'],
      receiverId: json['receiverId'],
      createdAt: DateTime.parse(json['requestedAt'] ?? json['createdAt']),
      status: json['relationshipStatus'] ?? json['status'],
    );
  }
}
*/
