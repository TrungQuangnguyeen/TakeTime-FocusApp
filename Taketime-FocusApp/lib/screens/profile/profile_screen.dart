import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/blocked_apps/usage_statistics_screen.dart'; // Import cho AppUsageStatisticsScreen
import '../../screens/main_screen.dart'; // Import cho MainScreen
import '../../screens/login/login_screen.dart'; // Import cho LoginScreen
import '../../services/auth_service.dart'; // Import AuthService

class ProfileScreen extends StatefulWidget {
  final AuthService authService; // Add this
  final Function(bool) onThemeChanged; // Add this

  const ProfileScreen({super.key, required this.authService, required this.onThemeChanged}); // Modify constructor

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Đang tải..."; // Giá trị mặc định
  String _userEmail = "Đang tải..."; // Giá trị mặc định
  String? _avatarUrl; // Thêm để lưu URL avatar từ Supabase
  File? _profileImage; // Giữ lại để xử lý avatar local
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingProfile = true;

  // Sample data for statistics
  final List<double> weeklyUsageData = [3.2, 2.8, 3.7, 4.5, 2.9, 3.8, 4.2];
  final List<String> weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  
  @override
  void initState() {
    super.initState();
    _fetchAndSetUserProfile();
    _loadProfileImage(); // Giữ lại để tải avatar local nếu có
  }

  Future<void> _fetchAndSetUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
    });

    final userProfileData = await widget.authService.fetchUserProfile();

    if (!mounted) return;

    setState(() {
      if (userProfileData != null) {
        // Sử dụng các key đã được chuẩn hóa trong fetchUserProfile
        _userName = userProfileData['full_name'] ?? userProfileData['username'] ?? "Người dùng";
        _userEmail = userProfileData['email'] ?? "Không có email";
        _avatarUrl = userProfileData['avatar_url']; 
        
        print("ProfileScreen: User profile loaded: Name: $_userName, Email: $_userEmail, Avatar: $_avatarUrl");

      } else {
        final currentUser = widget.authService.currentUser;
        if (currentUser != null && currentUser.email != null) {
          _userName = "Người dùng"; 
          _userEmail = currentUser.email!;
        } else {
          _userName = "Người dùng";
          _userEmail = "Lỗi tải hồ sơ";
        }
        print("ProfileScreen: Failed to load user profile. Fallback: Name: $_userName, Email: $_userEmail");
      }
      _isLoadingProfile = false;
    });
  }

  // Hàm tải ảnh đại diện từ SharedPreferences
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        setState(() {
          _profileImage = file;
        });
      }
    }
  }

  // Hàm lưu đường dẫn ảnh đại diện
  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);
  }

  // Hàm chụp ảnh mới
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _profileImage = File(photo.path);
      });
      await _saveProfileImagePath(photo.path);
      Navigator.pop(context);
    }
  }
  
  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      await _saveProfileImagePath(image.path);
      Navigator.pop(context);
    }
  }

  // Hàm lưu thông tin người dùng
  Future<void> _saveUserData(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header với background gradient
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4776E6),
                      Color(0xFF8E54E9),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // App Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button - Sửa để quay về trang chính
                          IconButton(
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                // Trường hợp không có màn hình nào để pop, có thể điều hướng đến MainScreen
                                // hoặc xử lý theo logic của ứng dụng.
                                // Ví dụ: Navigator.of(context).pushReplacement(...);
                              }
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          // Edit & Settings
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  _showEditProfileDialog(context);
                                },
                                icon: const Icon(Icons.edit, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Thêm chức năng đăng xuất cho nút cài đặt
                                  _showSettingsMenu(context);
                                },
                                icon: const Icon(Icons.settings, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Avatar with edit button
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Avatar
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: _isLoadingProfile
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white)) // Hiển thị loading cho avatar
                                  : _profileImage != null
                                      ? Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : _avatarUrl != null && _avatarUrl!.isNotEmpty
                                          ? Image.network( // Hiển thị avatar từ URL nếu có
                                              _avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                print("Error loading network avatar: $error");
                                                return Image.asset('assets/avatar.jpg', fit: BoxFit.cover); // Fallback nếu lỗi tải URL
                                              },
                                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            )
                                          : Image.asset( // Fallback cuối cùng nếu không có local và URL
                                              'assets/avatar.jpg',
                                              fit: BoxFit.cover,
                                            ),
                            ),
                          ),
                          // Camera icon
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: InkWell(
                              onTap: () => _showChangePhotoOptions(context),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // User Name
                      Text(
                        _isLoadingProfile ? "Đang tải..." : _userName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingProfile ? "Đang tải..." : _userEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Stats Row (23 - 17 - 85%)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat('23', 'Ngày sử dụng'),
                            _buildVerticalDivider(),
                            _buildStat('17', 'Thành tích'),
                            _buildVerticalDivider(),
                            _buildStat('85%', 'Hiệu suất'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Thống kê sử dụng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống kê sử dụng',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Usage chart card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with dropdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Thời gian tập trung hàng tuần',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // Dropdown for week selection
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Tuần này',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Bar chart
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceEvenly,
                                maxY: 5,
                                minY: 0,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          weekDays[value.toInt()],
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      },
                                      reservedSize: 25,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 1 == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              '${value.toInt()}h',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 25,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(
                                  weeklyUsageData.length,
                                  (index) => BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: weeklyUsageData[index],
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Button
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AppUsageStatisticsScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF4776E6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timeline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Xem chi tiết hoạt động',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bottom navigation padding
                    SizedBox(height: size.height * 0.08),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: _isLoadingProfile ? "" : _userName);
    final TextEditingController emailController = TextEditingController(text: _isLoadingProfile ? "" : _userEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chỉnh sửa thông tin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const AssetImage('assets/avatar.jpg') as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.blue,
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                readOnly: true, // Email thường không cho sửa trực tiếp, lấy từ Supabase Auth
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              // Chỉ lưu tên nếu email là read-only
              _saveUserData(nameController.text, _userEmail); 
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cập nhật thông tin thành công', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Lưu', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showChangePhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text('Chụp ảnh mới', style: GoogleFonts.poppins()),
            onTap: _takePhoto,
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text('Chọn từ thư viện', style: GoogleFonts.poppins()),
            onTap: _pickImageFromGallery,
          ),
        ],
      ),
    );
  }

  // Thêm hàm hiển thị menu cài đặt khi nhấn vào nút cài đặt
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('Cài đặt tài khoản', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  // Có thể thêm các tùy chọn cài đặt khác ở đây
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text('Đăng xuất', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Thêm hàm hiển thị hộp thoại xác nhận đăng xuất
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đăng xuất', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?', style: GoogleFonts.poppins()),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Đăng xuất', style: GoogleFonts.poppins(color: Colors.white)),
              onPressed: () {
                // Đóng hộp thoại xác nhận
                Navigator.of(context).pop(); 
                
                // Gọi hàm đăng xuất và điều hướng về màn hình đăng nhập
                // Xóa thông tin đăng nhập từ SharedPreferences
                _handleLogout(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Thêm hàm xử lý đăng xuất
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Xóa thông tin đăng nhập từ SharedPreferences (nếu bạn dùng cho việc khác ngoài session Supabase)
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('user_name'); 
      // await prefs.remove('user_email');
      // await prefs.remove('profile_image_path');
      // await prefs.setBool('is_logged_in', false); // This might not be needed if relying on Supabase session

      await widget.authService.signOut(); // Use AuthService to sign out from Supabase
      
      // onAuthStateChange in app.dart should handle navigation to LoginScreen
      // No need to manually push LoginScreen here if app.dart handles it.
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(
      //     builder: (context) => LoginScreen(
      //       onLogin: () {
      //         // Xử lý đăng nhập thành công ở đây nếu cần
      //       },
      //     ),
      //   ),
      //   (route) => false,
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi đăng xuất', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}