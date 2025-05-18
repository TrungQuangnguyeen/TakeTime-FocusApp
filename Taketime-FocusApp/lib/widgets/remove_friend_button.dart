import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class RemoveFriendButton extends StatelessWidget {
  final UserModel user;

  const RemoveFriendButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận hủy kết bạn'),
              content: Text(
                'Bạn có chắc chắn muốn hủy kết bạn với ${user.username}?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    bool success = await userProvider.removeFriend(user.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Đã hủy kết bạn với ${user.username}'
                                : 'Lỗi khi hủy kết bạn',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(Icons.person_remove),
      label: const Text('Hủy kết bạn'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
