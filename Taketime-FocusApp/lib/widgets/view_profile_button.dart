import 'package:flutter/material.dart';
import '../screens/friend/friend_detail_screen.dart';

class ViewProfileButton extends StatelessWidget {
  final String userId;

  const ViewProfileButton({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendDetailScreen(userId: userId),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('Xem chi tiết'),
    );
  }
}
