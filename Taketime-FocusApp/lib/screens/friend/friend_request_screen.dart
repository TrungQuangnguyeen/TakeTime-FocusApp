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
        body: const Center(child: CircularProgressIndicator()),
      );
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
          centerTitle: true,
          bottom: const TabBar(
            tabs: [Tab(text: 'Đã nhận'), Tab(text: 'Đã gửi')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestList(
              context,
              userProvider.incomingFriendRequests,
              true,
            ),
            _buildRequestList(
              context,
              userProvider.outgoingFriendRequests,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(
    BuildContext context,
    List requests,
    bool isIncoming,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Không có lời mời nào'),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(
            isIncoming ? req.requesterName ?? req.requesterId : req.receiverId,
          ),
          subtitle: Text(isIncoming ? req.requesterEmail ?? '' : ''),
          trailing:
              isIncoming
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).acceptFriendRequest(req.friendshipId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).rejectFriendRequest(req.friendshipId);
                        },
                      ),
                    ],
                  )
                  : const Text('Đã gửi', style: TextStyle(color: Colors.grey)),
        );
      },
    );
  }
}
