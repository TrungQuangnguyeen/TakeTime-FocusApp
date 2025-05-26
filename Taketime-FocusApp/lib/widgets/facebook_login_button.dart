import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Hoặc dùng Image.asset

class FacebookLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FacebookLoginButton({Key? key, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: SvgPicture.asset(
        'assets/facebook_icon.svg', // Corrected path
        height: 30.0, // Increased size
        width: 30.0, // Increased size
      ),
      label: const Text('Đăng nhập với Facebook'),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1877F2), // Màu của Facebook
        minimumSize: const Size(double.infinity, 50), // Full width
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
