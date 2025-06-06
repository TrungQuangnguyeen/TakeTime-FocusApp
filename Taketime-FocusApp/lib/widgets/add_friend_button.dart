import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddFriendButton extends StatelessWidget {
  final UserModel user;

  const AddFriendButton({super.key, required this.user});

  Future<void> _sendFriendRequest(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể gửi lời mời: Người dùng hiện tại không xác định.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final receiverId = user.id;

    final success = await userProvider.sendFriendRequest(receiverId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lời mời kết bạn.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi lời mời kết bạn thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isLoading = userProvider.isLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : () => _sendFriendRequest(context),
      child:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Text('Kết bạn'),
    );
  }
}
