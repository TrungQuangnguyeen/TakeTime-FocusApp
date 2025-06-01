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
  bool _requestSent = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkRequestStatus();
  }

  @override
  void didUpdateWidget(covariant AddFriendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.id != oldWidget.user.id) {
      _checkRequestStatus();
    }
  }

  Future<void> _checkRequestStatus() async {
    // Implement check if a friend request is already pending or accepted
    // This would involve fetching data from backend
    // For now, we'll assume no pending requests initially
  }

  Future<void> _sendFriendRequest() async {
    setState(() {
      _isSending = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      setState(() {
        _isSending = false;
      });
      return;
    }

    final requestData = {
      'sender_id': currentUser.id,
      'receiver_id': widget.user.id,
    };

    try {
      final url = Uri.parse('${userProvider.baseUrl}/api/FriendRequest');

      final response = await http.post(
        url,
        headers: userProvider.headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _requestSent = true;
        });
      } else {
        // Handle errors (e.g., request already exists, user not found)
        // Dựa vào response.body để hiểu rõ lỗi
      }
    } catch (e, stack) {
      // Hiển thị thông báo lỗi
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requestSent) {
      return const Text('Đã gửi lời mời', style: TextStyle(color: Colors.grey));
    } else if (_isSending) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      return ElevatedButton(
        onPressed: _sendFriendRequest,
        child: const Text('Kết bạn'),
      );
    }
  }
}
