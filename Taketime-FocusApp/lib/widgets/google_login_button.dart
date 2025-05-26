import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Hoặc dùng Image.asset nếu bạn có icon dạng png/jpg

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleLoginButton({Key? key, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: SvgPicture.asset(
        'assets/google_icon.svg',
        height: 30.0, // Increased size
        width: 30.0, // Increased size
      ),
      label: const Text('Đăng nhập với Google'),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50), // Full width
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
