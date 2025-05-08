import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:smartmanagementapp/services/auth_service.dart';
import 'package:smartmanagementapp/widgets/google_login_button.dart';
import 'package:smartmanagementapp/widgets/facebook_login_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _backgroundAnimationController;
  late AuthService _authService; // Declare AuthService instance

  @override
  void initState() {
    super.initState();
    _authService = AuthService(); // Initialize AuthService
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment(_backgroundAnimationController.value, 0.8),
                    colors: const [
                      Color(0xFF4E6AF3), // Primary color
                      Color(0xFF00CFDE), // Secondary color
                      Color(0xFF4E6AF3), // Primary color
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Animated Floating Bubbles
          ...List.generate(
            5,
            (index) => Positioned(
              top: screenSize.height * (index * 0.15),
              left: screenSize.width * (index % 2 == 0 ? 0.1 : 0.6),
              child: FadeInDown(
                delay: Duration(milliseconds: 200 * index),
                duration: const Duration(milliseconds: 1500),
                child: AnimatedBuilder(
                  animation: _backgroundAnimationController,
                  builder: (context, child) {
                    return Container(
                      width: 100 + (index * 30),
                      height: 100 + (index * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03 + (index * 0.01)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Animation
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4E6AF3).withOpacity(0.3),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.auto_awesome,
                              size: 55,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // App Title with Animation
                      FadeInDown(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 300),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'TakeTime',
                              textStyle: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              speed: const Duration(milliseconds: 100),
                            ),
                          ],
                          totalRepeatCount: 1,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Tagline
                      FadeInDown(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          "Quản lý thông minh, tối ưu hiệu suất",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login Card with Glassmorphism
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 800),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          // Adjusted height if necessary, or let it size by children
                          height: 250, 
                          borderRadius: 30,
                          blur: 10,
                          alignment: Alignment.center,
                          border: 2,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.6),
                              Colors.white.withOpacity(0.3),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Sử dụng GoogleLoginButton mới
                                FadeInUp(
                                  delay: const Duration(milliseconds: 800),
                                  child: GoogleLoginButton(
                                    onPressed: () async {
                                      try {
                                        await _authService.signInWithGoogle();
                                        // onAuthStateChange in app.dart will handle navigation
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Lỗi đăng nhập Google: ${e.toString()}")),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Sử dụng FacebookLoginButton mới
                                FadeInUp(
                                  delay: const Duration(milliseconds: 900), // delay +100ms
                                  child: FacebookLoginButton(
                                    onPressed: () async {
                                      try {
                                        await _authService.signInWithFacebook();
                                        // onAuthStateChange in app.dart will handle navigation
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Lỗi đăng nhập Facebook: ${e.toString()}")),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Nút đăng nhập khách (giữ nguyên nếu cần)
                                _buildSocialLoginButton( // Giữ lại hàm này cho nút Khách
                                  context,
                                  "Tiếp tục với tư cách khách",
                                  Colors.grey.shade700,
                                  Icons.person_outline,
                                  () async {
                                    try {
                                      await _authService.signInAsGuest(); // Now uses Supabase anonymous sign-in
                                      // onAuthStateChange in app.dart will handle navigation
                                    } catch (e) {
                                       if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Lỗi đăng nhập khách: ${e.toString()}")),
                                        );
                                      }
                                    }
                                  },
                                  delayMs: 200, // So với FadeInUp gốc là 800 + 200 = 1000ms
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Terms and Policy
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 1200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "Bằng cách đăng nhập, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Giữ lại hàm này nếu bạn vẫn dùng cho nút "Tiếp tục với tư cách khách"
  // Hoặc bạn có thể tạo một widget riêng cho nút khách nếu muốn.
  Widget _buildSocialLoginButton(
    BuildContext context,
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed, {
    required int delayMs,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: 800 + delayMs), // Giữ nguyên logic delay gốc
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          label: Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );
  }
}