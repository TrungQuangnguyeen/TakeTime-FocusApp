import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class RemoveFriendButton extends StatelessWidget {
  final UserModel user;

  const RemoveFriendButton({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return ElevatedButton.icon(
      onPressed: () async {
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hủy kết bạn'),
            content: Text('Bạn muốn hủy kết bạn với ${user.username}?'),
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
  }
}
