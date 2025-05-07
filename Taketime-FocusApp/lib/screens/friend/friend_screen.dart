import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'friend_detail_screen.dart';
import 'friend_request_screen.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Khởi tạo dữ liệu user nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) {
        userProvider.initUsers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết bạn'),
        centerTitle: true,
        actions: [
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
          tabs: const [
            Tab(text: 'Bạn bè'),
            Tab(text: 'Tìm kiếm'),
          ],
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
    final friends = userProvider.friends;

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friends.isEmpty) {
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _buildFriendCard(friend, theme, userProvider);
      },
    );
  }

  Widget _buildSearchTab(UserProvider userProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Tìm bạn bè bằng User ID',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Nhập User ID (VD: user456)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _searchUserId = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchUserId = value;
              });
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _isSearching = true;
                });
                userProvider.searchUserById(value);
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _searchUserId.isNotEmpty
                ? () {
                    setState(() {
                      _isSearching = true;
                    });
                    userProvider.searchUserById(_searchUserId);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Tìm kiếm'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildSearchResults(userProvider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(UserProvider userProvider, ThemeData theme) {
    if (!_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập User ID để tìm kiếm bạn bè',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final foundUser = userProvider.getUserById(_searchUserId);
    if (foundUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: theme.colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Không hiển thị bản thân trong kết quả tìm kiếm
    if (foundUser.id == userProvider.currentUser?.id) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Đây là ID của bạn',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildFriendCard(foundUser, theme, userProvider);
  }

  Widget _buildFriendCard(UserModel user, ThemeData theme, UserProvider userProvider) {
    final currentUser = userProvider.currentUser;
    final isFriend = currentUser?.friendIds.contains(user.id) ?? false;

    // Kiểm tra xem đã gửi lời mời kết bạn chưa

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(user.avatarUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.id}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hiệu suất: ${user.efficiency.toInt()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getEfficiencyColor(user.efficiency),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendDetailScreen(userId: user.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(user, userProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(UserModel user, UserProvider userProvider) {
    final currentUser = userProvider.currentUser;
    final isFriend = currentUser?.friendIds.contains(user.id) ?? false;
    final hasPendingRequest = userProvider.outgoingRequests.any(
      (request) => request.receiverId == user.id
    );

    if (isFriend) {
      return ElevatedButton.icon(
        onPressed: () async {
          // Hiển thị dialog xác nhận
          bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hủy kết bạn'),
              content: Text('Bạn muốn hủy kết bạn với ${user.name}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Đồng ý'),
                ),
              ],
            ),
          ) ?? false;

          if (confirm) {
            await userProvider.removeFriend(user.id);
          }
        },
        icon: const Icon(Icons.person_remove),
        label: const Text('Hủy kết bạn'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    } else if (hasPendingRequest) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('Đã gửi lời mời'),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () {
          userProvider.sendFriendRequest(user.id);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Kết bạn'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 85) {
      return Colors.green;
    } else if (efficiency >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}