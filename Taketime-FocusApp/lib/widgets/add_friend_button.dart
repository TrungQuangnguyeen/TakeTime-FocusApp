import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddFriendButton extends StatefulWidget {
  final UserModel user;

  const AddFriendButton({super.key, required this.user});

  @override
  State<AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<AddFriendButton> {
  bool _isSending = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Ưu tiên kiểm tra trạng thái friendshipStatus từ user
    if (widget.user.friendshipStatus == 'pending' ||
        widget.user.friendshipStatus == 'request_sent') {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top, color: Colors.grey),
        label: const Text('Đã gửi', style: TextStyle(color: Colors.grey)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    // Nếu đã gửi request, hoặc provider báo đã gửi, hiển thị nút "Đã gửi"
    if (_sent || userProvider.hasSentFriendRequestTo(widget.user.id)) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top, color: Colors.grey),
        label: const Text('Đã gửi', style: TextStyle(color: Colors.grey)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed:
          _isSending
              ? null
              : () async {
                print('DEBUG: Đã ấn nút kết bạn với id: ${widget.user.id}');
                setState(() => _isSending = true);
                // Gửi request trực tiếp tại đây để log chi tiết
                final currentUser = userProvider.currentUser;
                if (currentUser == null) {
                  print('ERROR: currentUser is null');
                  setState(() => _isSending = false);
                  return;
                }
                print(
                  'DEBUG: requesterId = \\${currentUser.id}, receiverId = \\${widget.user.id}',
                );
                try {
                  final response = await http.post(
                    Uri.parse(userProvider.baseUrl + '/api/FriendShip/send'),
                    headers: userProvider.headers,
                    body: jsonEncode({
                      'requesterId': currentUser.id,
                      'receiverId': widget.user.id,
                    }),
                  );
                  print('SendFriendRequest status: \\${response.statusCode}');
                  print('SendFriendRequest body: \\${response.body}');
                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    await userProvider.fetchFriendRequests();
                    setState(() {
                      _isSending = false;
                      _sent = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã gửi lời mời kết bạn!')),
                    );
                  } else {
                    setState(() => _isSending = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gửi lời mời thất bại! Mã lỗi: \\${response.statusCode}',
                        ),
                      ),
                    );
                  }
                } catch (e, stack) {
                  print('Error sending friend request: \\${e.toString()}');
                  print('STACKTRACE: \\${stack.toString()}');
                  setState(() => _isSending = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gửi lời mời thất bại! (Exception)'),
                    ),
                  );
                }
              },
      icon: const Icon(Icons.person_add),
      label: _isSending ? const Text('Đang gửi...') : const Text('Kết bạn'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
