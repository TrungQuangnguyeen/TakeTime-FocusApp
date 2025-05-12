import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class AddFriendButton extends StatelessWidget {
  final UserModel user;

  const AddFriendButton({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
