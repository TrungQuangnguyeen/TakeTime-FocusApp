import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../models/friend_request_model.dart'; // Added import
import 'friend_detail_screen.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.fetchFriendRequests();
      // We might need to fetch current user if not already available
      if (userProvider.currentUser == null) {
        userProvider.fetchCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null && userProvider.isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Lời mời kết bạn')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (currentUser == null && !userProvider.isLoading) {
       return Scaffold(
        appBar: AppBar(title: const Text('Lời mời kết bạn')),
        body: const Center(
          child: Text('Không thể tải dữ liệu người dùng. Vui lòng thử lại.'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lời mời kết bạn'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đã nhận'),
              Tab(text: 'Đã gửi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab lời mời đã nhận
            _buildRequestList(context, userProvider.incomingFriendRequests, "Lời mời đã nhận", true),

            // Tab lời mời đã gửi
            _buildRequestList(context, userProvider.outgoingFriendRequests, "Lời mời đã gửi", false),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(
    BuildContext context,
    List<FriendRequest> requests,
    String title,
    bool isIncoming,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);

    if (userProvider.isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncoming ? Icons.inbox_outlined : Icons.outbox_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isIncoming ? 'Không có lời mời nào' : 'Không có lời mời đã gửi',
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        // Fetch user details for the sender/receiver
        return FutureBuilder<UserModel?>(
          future: userProvider.fetchUserByIdFromApi(isIncoming ? request.requesterId : request.receiverId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card( // Show a card-styled loader
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(radius: 28, child: CircularProgressIndicator(strokeWidth: 2,)),
                  title: Text('Đang tải thông tin...'),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Card( // Show a card-styled error
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.errorContainer,
                      child: Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer)),
                  title: Text(isIncoming ? 'Không tìm thấy người gửi' : 'Không tìm thấy người nhận'),
                  subtitle: Text('ID: ${isIncoming ? request.requesterId : request.receiverId}'),
                ),
              );
            }
            final user = snapshot.data!;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.surfaceVariant, // Fallback color
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : const AssetImage('assets/avatar.jpg') as ImageProvider,
                  // Child is shown if backgroundImage fails to load an image.
                  child: Icon(Icons.person_outline, size: 32, color: theme.colorScheme.onSurfaceVariant),
                ),
                title: Text(user.username, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  isIncoming ? 'Đã gửi cho bạn lời mời kết bạn' : 'Bạn đã gửi lời mời đến người này',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: isIncoming
                    ? _buildIncomingRequestActions(context, userProvider, request, user.username, theme) // Pass username
                    : _buildOutgoingRequestStatus(request, theme),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendDetailScreen(userId: user.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomingRequestActions(BuildContext context, UserProvider userProvider, FriendRequest request, String requestUsername, ThemeData theme) {
    // A stateful wrapper could be used here if we want to show loading per button
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 28),
          tooltip: 'Chấp nhận',
          onPressed: () async {
            // TODO: Consider adding a local loading state for this specific item/button
            bool success = await userProvider.acceptFriendRequest(request.friendshipId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã chấp nhận lời mời từ $requestUsername' : 'Lỗi khi chấp nhận lời mời'),
                  backgroundColor: success ? Colors.green : theme.colorScheme.error,
                ),
              );
              // The list will refresh due to UserProvider notifying listeners after fetching data.
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.highlight_off, color: Colors.red.shade600, size: 28),
          tooltip: 'Từ chối',
          onPressed: () async {
            bool success = await userProvider.rejectFriendRequest(request.friendshipId);
             if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã từ chối lời mời từ $requestUsername' : 'Lỗi khi từ chối lời mời'),
                  backgroundColor: success ? Colors.orange : theme.colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildOutgoingRequestStatus(FriendRequest request, ThemeData theme) {
    return Text(
      _translateStatus(request.status),
      style: TextStyle(
        color: _getStatusColor(request.status, theme),
        fontWeight: FontWeight.bold,
        fontSize: theme.textTheme.bodySmall?.fontSize,
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) { // Ensure case-insensitivity
      case 'pending':
        return 'Đang chờ';
      case 'accepted':
        return 'Đã chấp nhận';
      case 'rejected':
      case 'denied': // Handle 'denied' as well if API might use it
        return 'Đã từ chối';
      default:
        return status; // Return original status if unknown
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}