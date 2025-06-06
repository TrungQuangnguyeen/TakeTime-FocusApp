import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'friend_detail_screen.dart';
import 'friend_request_screen.dart';
import '../../widgets/add_friend_button.dart';
import '../../widgets/remove_friend_button.dart';
import '../../widgets/request_sent_button.dart';
import '../../widgets/view_profile_button.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false; // To track if a search has been performed
  String _searchQuery = ""; // To store the current search query

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Optionally, fetch initial data if not handled elsewhere
    // Provider.of<UserProvider>(context, listen: false).fetchFriends();
    // Provider.of<UserProvider>(context, listen: false).fetchFriendRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(UserProvider userProvider) {
    if (_searchController.text.trim().isNotEmpty) {
      setState(() {
        _isSearching = true; // Indicate that search is active
        _searchQuery = _searchController.text.trim();
      });
      userProvider.searchUsersByQuery(_searchQuery);
    } else {
      // Clear search results if query is empty
      setState(() {
        _isSearching = false;
        _searchQuery = "";
        userProvider.searchedUsers.clear(); // Clear the list in provider
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BẠN BÈ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              userProvider.fetchFriends();
              userProvider.fetchFriendRequests();
            },
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendRequestScreen(),
                ),
              );
            },
            tooltip: 'Lời mời kết bạn',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          indicatorColor: primaryColor,
          tabs: const [Tab(text: 'Bạn bè'), Tab(text: 'Tìm kiếm')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab danh sách bạn bè
          _buildFriendsTab(userProvider, theme),

          // Tab tìm kiếm
          _buildSearchTab(userProvider, theme),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(UserProvider userProvider, ThemeData theme) {
    // final friends = userProvider.friends; // Original line - now directly use userProvider.friends

    // TEMPORARY MOCK DATA REMOVED - Relying on API data via UserProvider
    // List<UserModel> displayFriends = List.from(userProvider.friends);
    // if (userProvider.friends.isEmpty && !userProvider.isLoading /* && userProvider.currentUser != null */) {
    //     // ignore: avoid_print
    //     print('[DEBUG] Using MOCK friend data for UI preview in _buildFriendsTab. Remove this for production. CurrentUser check relaxed for mock data display.');
    //     displayFriends = [
    //         UserModel(id: 'mockuser1', username: 'Alice Wonderland', email: 'alice.w@example.com', avatarUrl: 'https://i.pravatar.cc/150?u=alice', friendshipId: 'fs_mock1'),
    //         UserModel(id: 'mockuser2', username: 'Bob The Great', email: 'bob.g@example.com', avatarUrl: null, friendshipId: 'fs_mock2'), // No avatar
    //         UserModel(id: 'mockuser3', username: 'Charlie Cool', email: 'charlie.c@example.com', avatarUrl: 'https://i.pravatar.cc/150?u=charlie', friendshipId: 'fs_mock3'),
    //         UserModel(id: 'mockuser4', username: 'Diana Daring', email: 'diana.d@example.com', avatarUrl: 'https://i.pravatar.cc/150?u=diana', friendshipId: 'fs_mock4'),
    //     ];
    // }
    // END TEMPORARY MOCK DATA

    final displayFriends = userProvider.friends; // Use actual friends list

    if (userProvider.isLoading && displayFriends.isEmpty) {
      // Show loader only if displayFriends list is empty and loading
      return const Center(child: CircularProgressIndicator());
    }

    if (displayFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có kết nối nào',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kết nối với người khác để theo dõi tiến độ của họ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.search),
              label: const Text('Tìm kiếm bạn bè'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayFriends.length,
      itemBuilder: (context, index) {
        final friend = displayFriends[index];
        return _buildFriendCard(
          friend,
          theme,
          userProvider,
          isSearchResult: false,
        );
      },
    );
  }

  Widget _buildSearchTab(UserProvider userProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tìm bạn bè bằng tên',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Nhập tên người dùng',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch(userProvider); // Clear results
                          setState(() {
                            _isSearching = false; // Reset search state
                          });
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              // Update search query state for enabling button or live search (optional)
              setState(() {
                // _searchQuery = value; // If needed for other logic
              });
            },
            onSubmitted: (value) {
              _performSearch(userProvider);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Tìm kiếm'),
            onPressed:
                _searchController.text.trim().isNotEmpty
                    ? () => _performSearch(userProvider)
                    : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: theme.textTheme.titleMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildSearchResults(userProvider, theme)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(UserProvider userProvider, ThemeData theme) {
    if (!_isSearching) {
      // If no search has been performed yet
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa để tìm kiếm người dùng.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final foundUsers = userProvider.searchedUsers;

    if (foundUsers.isEmpty && _isSearching) {
      // If search was done but no results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 80,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng nào cho "${_searchQuery}".',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử lại với từ khóa khác.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Filter out the current user from search results
    final displayUsers =
        foundUsers
            .where((user) => user.id != userProvider.currentUser?.id)
            .toList();

    if (displayUsers.isEmpty && foundUsers.isNotEmpty) {
      // This case means the only user found was the current user.
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn không thể tự kết bạn với chính mình.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (displayUsers.isEmpty) {
      return Center(
        // Should be covered by the above cases, but as a fallback
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng nào khác.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayUsers.length,
      itemBuilder: (context, index) {
        // For search results, we always show AddFriendButton, RequestSentButton, or ViewProfileButton (if already friend)
        // The _buildActionButton will handle this logic.
        return _buildFriendCard(
          displayUsers[index],
          theme,
          userProvider,
          isSearchResult: true,
        );
      },
    );
  }

  Widget _buildFriendCard(
    UserModel user,
    ThemeData theme,
    UserProvider userProvider, {
    bool isSearchResult = false,
  }) {
    // Default avatar if URL is null or empty
    Widget avatarWidget;
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      try {
        avatarWidget = CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(user.avatarUrl!),
          backgroundColor: theme.colorScheme.surfaceVariant,
        );
      } catch (e) {
        // Fallback for invalid URL or network error
        avatarWidget = CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person_outline,
            size: 32,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        );
      }
    } else {
      // Fallback for null or empty URL
      avatarWidget = CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.person_outline,
          size: 32,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: avatarWidget,
        title: Text(
          user.username,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: _buildActionButton(user, userProvider, theme, isSearchResult),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FriendDetailScreen(
                    userId: user.id,
                  ), // Corrected: Pass userId
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    UserModel user,
    UserProvider userProvider,
    ThemeData theme,
    bool isSearchResult,
  ) {
    final bool isCurrentUser = user.id == userProvider.currentUser?.id;

    if (isCurrentUser) {
      // For the current user, always show ViewProfileButton, regardless of tab.
      return ViewProfileButton(userId: user.id);
    }

    // Scenario 1: Displaying in the "Friends" tab
    if (!isSearchResult) {
      // In the Friends tab, users are expected to be friends.
      // We show a "Remove Friend" button.
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (String result) async {
          // Make async to await showDialog
          if (result == 'remove') {
            // Show confirmation dialog before removing
            final bool confirmRemove =
                await showDialog(
                  // Await the dialog result
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Xác nhận hủy kết bạn'),
                      content: Text(
                        'Bạn có chắc chắn muốn hủy kết bạn với ${user.username} không?',
                      ), // Use user.username for clarity
                      actions: <Widget>[
                        TextButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(false), // Return false on cancel
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(true), // Return true on confirm
                          child: Text(
                            'Xác nhận',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ), // Use error color for emphasis
                          ),
                        ),
                      ],
                    );
                  },
                ) ??
                false; // Default to false if dialog is dismissed unexpectedly

            if (confirmRemove) {
              // Only proceed if user confirmed
              // Call the same logic as the original RemoveFriendButton
              userProvider.removeFriend(user.friendshipId!).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã hủy kết bạn thành công.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hủy kết bạn thất bại.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }
          }
        },
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_remove_alt_1,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hủy kết bạn',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
      );
    }
    // Scenario 2: Displaying in "Search Results" tab
    else {
      // isSearchResult is true
      // Prioritize friendshipStatus from the search result itself
      // Re-check status using UserProvider's methods for the most up-to-date state
      if (userProvider.isFriend(user.id)) {
        // Check if already friend
        return ViewProfileButton(userId: user.id);
      } else if (userProvider.hasSentFriendRequestTo(user.id)) {
        // Check if request sent
        return const RequestSentButton();
      } else if (userProvider.hasReceivedFriendRequestFrom(user.id)) {
        // Check if request received
        // If there's an incoming request from this user
        return ElevatedButton(
          onPressed: () {
            // Navigate to the friend request screen where they can accept/deny
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendRequestScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Phản hồi'), // "Respond"
        );
      } else {
        // isSearchResult is true
        // Use friendshipStatus provided in the search result directly for button display
        if (user.friendshipStatus == 'accepted') {
          // If the search result says they are already friends
          return ViewProfileButton(userId: user.id);
        } else if (user.friendshipStatus == 'request_sent') {
          // If the search result says a request has been sent by the current user
          return const RequestSentButton();
        } else if (user.friendshipStatus == 'request_received') {
          // If the search result says a request has been received by the current user
          // If there's an incoming request from this user
          return ElevatedButton(
            onPressed: () {
              // Navigate to the friend request screen where they can accept/deny
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendRequestScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Phản hồi'), // "Respond"
          );
        } else {
          // Not a friend, no pending requests either way according to both search status (not 'accepted') and provider lists.
          // This should be the case for displaying the AddFriendButton
          return AddFriendButton(user: user);
        }
      }
    }
  }
}
