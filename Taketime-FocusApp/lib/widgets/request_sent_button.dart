import 'package:flutter/material.dart';

class RequestSentButton extends StatelessWidget {
  const RequestSentButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: null, // Disabled
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('Đã gửi lời mời'),
    );
  }
}
