import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Management',
      home: MyLoginScreen(),
    );
  }
}

class MyLoginScreen extends StatelessWidget {
  const MyLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Đặt thanh trạng thái trong suốt
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D47A1), // Xanh đậm
                  Color(0xFF1976D2), // Xanh trung bình
                  Color(0xFF42A5F5), // Xanh nhạt
                ],
              ),
            ),
          ),
          
          // Hiệu ứng trang trí - các hình tròn
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          // Nội dung chính
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo hoặc Icon ứng dụng
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          size: 60,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Tên ứng dụng
                      Text(
                        "Smart Management",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Khẩu hiệu
                      Text(
                        "Quản lý thông minh, tối ưu hiệu suất",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Khung đăng nhập với hiệu ứng Glassmorphism
                      GlassmorphicContainer(
                        width: double.infinity,
                        height: 280,
                        borderRadius: 20,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Nút đăng nhập Gmail
                              _buildLoginButton(
                                context,
                                "Đăng nhập với Gmail",
                                const Color(0xFFDB4437),
                                Icons.email_outlined,
                                () {
                                  // Xử lý đăng nhập Gmail
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đăng nhập với Gmail")),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Nút đăng nhập Facebook
                              _buildLoginButton(
                                context,
                                "Đăng nhập với Facebook",
                                const Color(0xFF3b5998),
                                Icons.facebook,
                                () {
                                  // Xử lý đăng nhập Facebook
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đăng nhập với Facebook")),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Nút đăng nhập khách
                              _buildLoginButton(
                                context,
                                "Tiếp tục với tư cách khách",
                                Colors.grey.shade700,
                                Icons.person_outline,
                                () {
                                  // Xử lý đăng nhập khách
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đăng nhập với tư cách khách")),
                                  );
                                },
                                isOutlined: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Điều khoản và chính sách bảo mật
                      Text(
                        "Bằng cách đăng nhập, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildLoginButton(
    BuildContext context,
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
        ),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          elevation: isOutlined ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined
                ? BorderSide(color: Colors.white.withOpacity(0.5), width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}