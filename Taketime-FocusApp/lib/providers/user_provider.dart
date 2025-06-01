import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/friend_request_model.dart'; // Correct import for FriendRequest
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

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
  final String _accessTokenKey = 'access_token';

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
      fetchCurrentUser().then((_) {
        if (_currentUser != null) {
          fetchFriends();
          fetchFriendRequests();
          fetchUserProject();
        }
      });
    } else {
      print('[UserProvider] Auth token cleared. Clearing user data.');
      _currentUser = null;
      _friends = [];
      _incomingFriendRequests = [];
      _outgoingFriendRequests = [];
      _acceptedFriendships = [];
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
      _currentUser = null;
      notifyListeners();
      return;
    }

    print(
      '[UserProvider] Current Access Token being used for /api/users/profile: $_accessToken',
    );

    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/profile'),
        headers: _headers,
      );

      print(
        '[UserProvider] Fetch Current User Status Code: ${response.statusCode}',
      );
      print(
        '[UserProvider] Fetch Current User Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(response.body);
        _currentUser = UserModel.fromJson(userData);
        print(
          '[UserProvider] fetchCurrentUser completed for user ID: ${_currentUser?.id}',
        );
      } else {
        print('Failed to fetch current user: ${response.statusCode}');
        await logout();
      }
    } catch (e) {
      print('Exception fetching current user: $e');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFriends() async {
    print('[UserProvider] fetchFriends called.');
    if (_accessToken == null || _currentUser == null) {
      print(
        '[UserProvider] fetchFriends: _accessToken or _currentUser is null, returning.',
      );
      _friends = [];
      notifyListeners();
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
      print('[UserProvider] Fetch Friends Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        for (var item in data) {
          try {
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
      _acceptedFriendships = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    List<FriendRequest> successfullyParsedRequests = [];
    int previousIncomingCount = _incomingFriendRequests.length;

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

        if (_incomingFriendRequests.length > previousIncomingCount) {
          notifyListeners();
        }

        print(
          '[UserProvider] Updated _outgoingFriendRequests: ${_outgoingFriendRequests.map((req) => '${req.friendshipId}:${req.status}').join(', ')}',
        );
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
      print(
        '[UserProvider] fetchFriendRequests completed. Parsed ${successfullyParsedRequests.length} requests. Incoming: ${_incomingFriendRequests.length}, Outgoing: ${_outgoingFriendRequests.length}, Accepted: ${_acceptedFriendships.length}',
      );
      notifyListeners();
    }
  }

  Future<UserModel?> fetchUserByIdFromApi(String userId) async {
    print('[UserProvider] fetchUserByIdFromApi called for userId: $userId');
    if (_accessToken == null) {
      print(
        '[UserProvider] fetchUserByIdFromApi: _accessToken is null, returning null.',
      );
      return null;
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId'),
        headers: _headers,
      );

      print(
        '[UserProvider] Fetch User By ID Status Code: ${response.statusCode}',
      );
      print('[UserProvider] Fetch User By ID Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final UserModel fetchedUser = UserModel.fromJson(data);
        print(
          '[UserProvider] Successfully fetched user by ID: ${fetchedUser.id}',
        );
        return fetchedUser;
      } else if (response.statusCode == 404) {
        print('[UserProvider] User with ID $userId not found (404).');
        return null;
      } else {
        print(
          '[UserProvider] Failed to fetch user by ID: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      print('[UserProvider] Exception fetching user by ID: $e');
      print('[UserProvider] StackTrace: $stackTrace');
      return null;
    }
  }

  Future<List<UserModel>> searchUsersByQuery(String query) async {
    print('[UserProvider] searchUsersByQuery called with query: "$query"');

    if (_accessToken == null) {
      print(
        '[UserProvider] searchUsersByQuery: _accessToken is null. Aborting search.',
      );
      _searchedUsers = [];
      notifyListeners();
      return [];
    }
    if (query.isEmpty) {
      print(
        '[UserProvider] searchUsersByQuery: query is empty. Clearing results.',
      );
      _searchedUsers = [];
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _searchedUsers = [];
    notifyListeners();
    print(
      '[UserProvider] searchUsersByQuery: Cleared _searchedUsers and notified listeners. _isLoading is true.',
    );

    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final searchUrl = Uri.parse(
        '$_baseUrl/api/FriendShip/search?query=$encodedQuery',
      );
      print(
        '[UserProvider] searchUsersByQuery: Attempting to call API: $searchUrl',
      );

      final response = await http.get(searchUrl, headers: _headers);
      print('[UserProvider] Search Users Status Code: ${response.statusCode}');
      print('[UserProvider] Search Users Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        print(
          '[UserProvider] searchUsersByQuery: Successfully decoded response. Data length: [32m${data.length}[0m',
        );

        List<UserModel> parsedUsers = [];
        for (var jsonItem in data) {
          try {
            parsedUsers.add(
              UserModel.fromJson(jsonItem as Map<String, dynamic>),
            );
          } catch (e) {
            print(
              '[UserProvider] searchUsersByQuery: Error parsing user item: $jsonItem. Error: $e',
            );
          }
        }
        _searchedUsers = parsedUsers;
        print(
          '[UserProvider] searchUsersByQuery: Parsed ${_searchedUsers.length} users.',
        );
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
      print('[UserProvider] Error searching users (in catch block): $e');
      print('[UserProvider] StackTrace: $stackTrace');
      _searchedUsers = [];
    } finally {
      _isLoading = false;
      print(
        '[UserProvider] searchUsersByQuery: Completed. _isLoading is false. Searched users count: ${_searchedUsers.length}',
      );
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
      );
      if (response.statusCode == 200) {
        await fetchFriendRequests();
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

  Future<bool> removeFriend(String friendshipId) async {
    if (_accessToken == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/Friendship/remove/$friendshipId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _friends.removeWhere((friend) => friend.friendshipId == friendshipId);
        _acceptedFriendships.removeWhere(
          (req) => req.friendshipId == friendshipId,
        );

        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProject() async {
    print('[UserProvider] fetchUserProject called.');
    if (_accessToken == null || _currentUser == null) {
      print(
        '[UserProvider] fetchUserProject: _accessToken or _currentUser is null, returning.',
      );
      return;
    }

    final url = Uri.parse('$_baseUrl/api/Project');
    try {
      final response = await http.get(url, headers: _headers);

      print(
        '[UserProvider] Fetch User Project Status Code: ${response.statusCode}',
      );
      print(
        '[UserProvider] Fetch User Project Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectDataList = jsonDecode(response.body);

        if (projectDataList.isNotEmpty) {
          final Map<String, dynamic> projectData = projectDataList.first;
          final String? projectId = projectData['project_id'] as String?;

          if (projectId != null && _currentUser != null) {
            _currentUser = _currentUser!.copyWith(projectId: projectId);
            print(
              '[UserProvider] fetchUserProject: User projectId updated to $projectId.',
            );
            notifyListeners();
          } else {
            print(
              '[UserProvider] fetchUserProject: Project ID not found in response or currentUser is null.',
            );
          }
        } else {
          print(
            '[UserProvider] fetchUserProject: No projects found for the user (empty array).',
          );
        }
      } else {
        print(
          '[UserProvider] Failed to fetch user project: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[UserProvider] Exception fetching user project: $e');
    }
  }

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

  void updateCurrentUser(UserModel newUser) {
    _currentUser = newUser;
    notifyListeners();
  }

  Future<void> logout() async {
    // Implementation of logout method
  }

  Future<void> loadAccessToken() async {
    print('[UserProvider] loadAccessToken called.');
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    if (_accessToken != null) {
      print('[UserProvider] Access token loaded.');
      await fetchCurrentUser();
      if (_currentUser != null) {
        await fetchFriends();
        await fetchFriendRequests();
        await fetchUserProject();
      }
    } else {
      print('[UserProvider] No access token found.');
      _currentUser = null;
      _friends = [];
      _incomingFriendRequests = [];
      _outgoingFriendRequests = [];
      _acceptedFriendships = [];
      _searchedUsers = [];
    }
  }
}
