import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/blocked_apps/usage_statistics_screen.dart'; // Import cho AppUsageStatisticsScreen
import '../settings/permission_setup_screen.dart'; // Sửa đường dẫn import cho PermissionSetupScreen
import '../../services/auth_service.dart'; // Import AuthService
import '../../services/app_blocking_service.dart'; // Import AppBlockingService

class ProfileScreen extends StatefulWidget {
  final AuthService authService; // Add this
  final Function(bool) onThemeChanged; // Add this

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.onThemeChanged,
  }); // Modify constructor

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Đang tải..."; // Giá trị mặc định
  String _userEmail = "Đang tải..."; // Giá trị mặc định
  String? _avatarUrl; // Thêm để lưu URL avatar từ Supabase
  File? _profileImage; // Giữ lại để xử lý avatar local
  bool _isLoadingProfile = true;

  // Dữ liệu cho biểu đồ tròn (từ usage_statistics_screen.dart)
  late List<Map<String, dynamic>> _blockedApps; // Cần cho biểu đồ tròn
  late Map<String, Map<String, int>> _dailyUsageData; // Cần cho biểu đồ tròn

  @override
  void initState() {
    super.initState();
    _fetchAndSetUserProfile();
    _loadProfileImage(); // Giữ lại để tải avatar local nếu có

    // Khởi tạo dữ liệu cho biểu đồ tròn
    _blockedApps = [];
    _dailyUsageData = {};
    _loadUsageDataForPieChart(); // Tải dữ liệu sử dụng cho biểu đồ tròn
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
        _userName =
            userProfileData['full_name'] ??
            userProfileData['username'] ??
            "Người dùng";
        _userEmail = userProfileData['email'] ?? "Không có email";
        _avatarUrl = userProfileData['avatar_url'];

        print(
          "ProfileScreen: User profile loaded: Name: $_userName, Email: $_userEmail, Avatar: $_avatarUrl",
        );
      } else {
        final currentUser = widget.authService.currentUser;
        if (currentUser != null && currentUser.email != null) {
          _userName = "Người dùng";
          _userEmail = currentUser.email!;
        } else {
          _userName = "Người dùng";
          _userEmail = "Lỗi tải hồ sơ";
        }
        print(
          "ProfileScreen: Failed to load user profile. Fallback: Name: $_userName, Email: $_userEmail",
        );
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

  // Thêm hàm tải dữ liệu sử dụng cho biểu đồ tròn (chỉ cho ngày hôm nay)
  Future<void> _loadUsageDataForPieChart() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedAppsJson = prefs.getStringList('blocked_apps') ?? [];

    final List<Map<String, dynamic>> loadedApps = [];

    // Tải danh sách ứng dụng bị chặn (để lấy tên và màu)
    if (blockedAppsJson.isNotEmpty) {
      for (String jsonString in blockedAppsJson) {
        Map<String, dynamic> appData = json.decode(jsonString);

        // Chuyển đổi màu sắc từ JSON sang Color
        if (appData['color'] is String) {
          String colorString = appData['color'];
          int colorValue = int.parse(colorString.replaceAll('#', '0xFF'));
          appData['color'] = Color(colorValue);
        }
        loadedApps.add(appData);
      }
    }

    // Lấy dữ liệu sử dụng thực tế cho CHỈ ngày hôm nay sử dụng phương thức mới
    final Map<String, Map<String, int>> usageData = {};
    try {
      final permissions = await AppBlockingService.checkAllPermissions();
      if (permissions['usageStats'] == true) {
        // Chỉ lấy dữ liệu cho ngày hôm nay
        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(
          today.year,
          today.month,
          today.day,
          0,
          0,
          0,
        );
        DateTime endOfDay = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        );

        String dateString = _getDateStringForPieChart(today);
        usageData[dateString] = {};

        // Sử dụng phương thức mới để lấy dữ liệu usage cho ngày hôm nay
        final dailyUsage = await AppBlockingService.getUsageTimeForDateRange(
          startOfDay,
          endOfDay,
        );

        dailyUsage.forEach((packageName, minutes) {
          // Chỉ thêm vào nếu ứng dụng nằm trong danh sách bị chặn
          if (loadedApps.any((app) => app['packageName'] == packageName)) {
            usageData[dateString]![packageName] = minutes;
          }
        });

        print(
          'Real usage data loaded for pie chart in profile screen (Today only)',
        );
      } else {
        print(
          'Usage Stats permission not granted, cannot load real usage data for pie chart',
        );
        // Có thể thêm logic hiển thị thông báo hoặc dữ liệu mẫu ở đây
      }
    } catch (e) {
      print('Error loading real usage data for pie chart: $e');
      // Có thể thêm logic hiển thị thông báo lỗi hoặc dữ liệu mẫu ở đây
    }

    if (mounted) {
      setState(() {
        _blockedApps = loadedApps; // Cập nhật danh sách ứng dụng bị chặn
        _dailyUsageData =
            usageData; // usageData chỉ chứa dữ liệu của ngày hôm nay
      });
    }
  }

  // Helper function để lấy chuỗi ngày cho dailyUsageData (không đổi)
  String _getDateStringForPieChart(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper function để lấy tổng thời gian sử dụng trong ngày đã tải (ngày hôm nay)
  int _getTotalUsageForLoadedDay() {
    if (_dailyUsageData.isEmpty) return 0;
    // Lấy dữ liệu cho ngày hôm nay (key duy nhất trong _dailyUsageData)
    DateTime today = DateTime.now();
    String dateString = _getDateStringForPieChart(today);

    if (_dailyUsageData.containsKey(dateString)) {
      return _dailyUsageData[dateString]!.values.fold(
        0,
        (sum, minutes) => sum + minutes,
      );
    } else {
      return 0;
    }
  }

  // Widget hiển thị biểu đồ tròn và chi tiết (SAO CHÉP TỪ usage_statistics_screen.dart, ĐÃ CHỈNH SỬA NHỎ)
  Widget _buildPieChartSection() {
    // Lấy dữ liệu usage cho ngày hôm nay
    DateTime today = DateTime.now();
    String dateString = _getDateStringForPieChart(today);
    final Map<String, int> dayData = _dailyUsageData[dateString] ?? {};

    // Kiểm tra trạng thái dữ liệu
    if (_blockedApps.isEmpty ||
        dayData.isEmpty ||
        _getTotalUsageForLoadedDay() == 0) {
      return _buildEmptyStateForPieChart(); // Sử dụng empty state
    }

    // Lọc và sắp xếp các ứng dụng theo thời gian sử dụng
    List<MapEntry<String, int>> sortedEntries = dayData.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));

    // Giới hạn chỉ hiển thị 5 ứng dụng hàng đầu + nhóm "Khác"
    final int threshold = 5;
    List<MapEntry<String, int>> topEntries =
        sortedEntries.length > threshold
            ? sortedEntries.sublist(0, threshold)
            : sortedEntries;

    // Tính tổng thời gian "Khác"
    int otherMinutes = 0;
    if (sortedEntries.length > threshold) {
      for (int i = threshold; i < sortedEntries.length; i++) {
        otherMinutes += sortedEntries[i].value;
      }
    }

    // Tổng hợp dữ liệu cho biểu đồ tròn
    List<PieChartSectionData> sections = [];
    double totalMinutes = 0;
    List<Map<String, dynamic>> chartData = [];

    for (MapEntry<String, int> entry in topEntries) {
      totalMinutes += entry.value;
    }
    totalMinutes += otherMinutes;

    // Tạo các sections cho biểu đồ tròn và dữ liệu cho legend
    if (totalMinutes > 0) {
      for (int i = 0; i < topEntries.length; i++) {
        MapEntry<String, int> entry = topEntries[i];
        String packageName = entry.key;
        int minutes = entry.value;
        double percentage = minutes / totalMinutes;

        // Tìm thông tin ứng dụng từ danh sách đã lưu
        Map<String, dynamic>? appInfo;
        for (var app in _blockedApps) {
          if (app['packageName'] == packageName) {
            appInfo = app;
            break;
          }
        }

        // Sử dụng thông tin ứng dụng nếu tìm thấy, ngược lại dùng placeholder
        if (appInfo != null) {
          Color appColor =
              appInfo['color'] as Color? ??
              _getColorForIndex(
                i,
              ); // Sử dụng màu từ blockedApps hoặc màu mặc định
          String appName = appInfo['name']; // Lấy tên ứng dụng

          // Thêm section vào biểu đồ tròn (không hiển thị nhãn % trên biểu đồ)
          sections.add(
            PieChartSectionData(
              value: minutes.toDouble(),
              title: '',
              color: appColor,
              radius: 45, // Điều chỉnh kích thước của biểu đồ
              badgeWidget: null,
              showTitle: false,
            ),
          );

          // Lưu thông tin cho legend
          chartData.add({
            'name': appName,
            'minutes': minutes,
            'percentage': percentage,
            'color': appColor,
          });
        } else {
          // Xử lý trường hợp không tìm thấy thông tin ứng dụng (hiếm xảy ra nếu logic tải dữ liệu đúng)
          Color defaultColor = Colors.grey[300]!;
          String defaultName = packageName; // Sử dụng package name làm tên tạm

          sections.add(
            PieChartSectionData(
              value: minutes.toDouble(),
              title: '',
              color: defaultColor,
              radius: 45,
              badgeWidget: null,
              showTitle: false,
            ),
          );
          chartData.add({
            'name': defaultName,
            'minutes': minutes,
            'percentage': percentage,
            'color': defaultColor,
          });
        }
      }

      // Thêm phần "Khác" nếu có
      if (otherMinutes > 0) {
        double percentage = otherMinutes / totalMinutes;
        sections.add(
          PieChartSectionData(
            value: otherMinutes.toDouble(),
            title: '',
            color: Colors.grey, // Màu cho phần "Khác"
            radius: 65,
            showTitle: false,
          ),
        );

        chartData.add({
          'name': 'Khác',
          'minutes': otherMinutes,
          'percentage': percentage,
          'color': Colors.grey,
        });
      }
    }

    // Nếu không có dữ liệu, hiển thị biểu đồ trống
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.shade300,
          radius: 65,
          showTitle: false,
        ),
      );

      chartData.add({
        'name': 'Không có dữ liệu',
        'minutes': 0,
        'percentage': 1.0,
        'color': Colors.grey.shade300,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            ], // Sử dụng shadow nhẹ hơn
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân bổ thời gian sử dụng hôm nay', // Tiêu đề cố định
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ), // Font lớn hơn
              ),
              const SizedBox(height: 16),

              // Biểu đồ tròn và chú thích
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Biểu đồ tròn
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 0.9,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: sections,
                          pieTouchData: PieTouchData(
                            enabled: false,
                          ), // Tắt tương tác touch
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Chú thích bên phải - Hiển thị giống với thiết kế mẫu
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children:
                          chartData.map((data) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  // Đốm màu tròn
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: data['color'],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tên ứng dụng
                                  Expanded(
                                    // Thêm Expanded để tránh tràn văn bản
                                    child: Text(
                                      data['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ), // Font và độ dày
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Xử lý tràn văn bản
                                    ),
                                  ),
                                  // Phần trăm
                                  Text(
                                    '${(data['percentage'] * 100).toStringAsFixed(0)}%', // Định dạng phần trăm
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ), // Font và độ dày
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Chi tiết thời gian - hiển thị dưới dạng các nút bo tròn (SAO CHÉP TỪ usage_statistics_screen.dart)
        const SizedBox(height: 16),
        Container(
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
            ], // Sử dụng shadow nhẹ hơn
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết thời gian', // Tiêu đề
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ), // Font và độ dày
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, // Khoảng cách ngang giữa các chip
                runSpacing: 8, // Khoảng cách dọc giữa các dòng chip
                children:
                    chartData.map((data) {
                      // Loại bỏ chip "Không có dữ liệu" nếu có
                      if (data['name'] == 'Không có dữ liệu')
                        return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ), // Padding bên trong chip
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(
                            24,
                          ), // Bo tròn góc
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ), // Viền nhẹ
                        ),
                        child: Text(
                          '${data['name']}: ${data['minutes']} phút', // Nội dung chip
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ), // Font
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),

        // Chi tiết theo ứng dụng (Bảng) (SAO CHÉP TỪ usage_statistics_screen.dart, ĐÃ CHỈNH SỬA NHỎ)
        const SizedBox(height: 24), // Khoảng cách
        Container(
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
            ], // Sử dụng shadow nhẹ hơn
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết theo ứng dụng', // Tiêu đề
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ), // Font lớn hơn
              ),
              const SizedBox(height: 16), // Khoảng cách
              // Header bảng
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ), // Padding cho header
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ), // Đường kẻ dưới
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2, // Cột tên ứng dụng rộng hơn
                      child: Text(
                        'Ứng dụng', // Tiêu đề cột
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ), // Font
                      ),
                    ),
                    Expanded(
                      flex: 1, // Cột thời gian
                      child: Text(
                        'Thời gian', // Tiêu đề cột
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ), // Font
                        textAlign: TextAlign.end, // Căn phải
                      ),
                    ),
                    Expanded(
                      flex: 1, // Cột giới hạn
                      child: Text(
                        'Giới hạn', // Tiêu đề cột
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ), // Font
                        textAlign: TextAlign.end, // Căn phải
                      ),
                    ),
                  ],
                ),
              ),

              // Các dòng dữ liệu ứng dụng
              ...sortedEntries.map((entry) {
                String packageName = entry.key;
                int minutes = entry.value;

                // Tìm thông tin ứng dụng từ danh sách đã lưu
                Map<String, dynamic>? appInfo;
                for (var app in _blockedApps) {
                  if (app['packageName'] == packageName) {
                    appInfo = app;
                    break;
                  }
                }

                // Chỉ hiển thị nếu tìm thấy thông tin ứng dụng
                if (appInfo == null)
                  return const SizedBox.shrink(); // Ẩn dòng nếu không tìm thấy

                String appName = appInfo['name']; // Tên ứng dụng
                int limitMinutes =
                    appInfo['timeLimit'] ?? 0; // Giới hạn thời gian
                Color appColor =
                    appInfo['color'] as Color? ?? Colors.grey; // Màu sắc

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ), // Padding cho dòng
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ), // Đường kẻ dưới
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2, // Cột tên ứng dụng
                        child: Row(
                          children: [
                            // Icon ứng dụng (dùng màu từ blockedApps và icon mặc định hoặc tùy chỉnh)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: appColor.withAlpha(50), // Nền màu nhạt
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // Bo tròn góc icon
                              ),
                              child: Icon(
                                _getIconForAppName(
                                  appName,
                                ), // Lấy icon dựa trên tên ứng dụng
                                color: appColor, // Màu icon
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8), // Khoảng cách
                            Expanded(
                              child: Text(
                                appName, // Hiển thị tên ứng dụng
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ), // Font
                                overflow: TextOverflow.ellipsis, // Xử lý tràn
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1, // Cột thời gian sử dụng
                        child: Text(
                          '$minutes phút', // Thời gian sử dụng
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: minutes > limitMinutes ? Colors.red : null,
                            fontWeight: FontWeight.w500,
                          ), // Font và màu nếu quá giới hạn
                          textAlign: TextAlign.end, // Căn phải
                        ),
                      ),
                      Expanded(
                        flex: 1, // Cột giới hạn thời gian
                        child: Text(
                          limitMinutes == 0
                              ? 'Không giới hạn'
                              : '$limitMinutes phút', // Hiển thị giới hạn hoặc "Không giới hạn"
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ), // Font
                          textAlign: TextAlign.end, // Căn phải
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  // Widget hiển thị trạng thái trống cho biểu đồ tròn (Đã cập nhật)
  Widget _buildEmptyStateForPieChart() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu sử dụng hôm nay',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy sử dụng ứng dụng để xem thống kê.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppUsageStatisticsScreen(),
                ),
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
                const Icon(Icons.bar_chart, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Xem chi tiết thống kê',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get default color by index (from usage_statistics_screen.dart)
  Color _getColorForIndex(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  // Helper function to get icon based on app name (from usage_statistics_screen.dart)
  IconData _getIconForAppName(String appName) {
    switch (appName.toLowerCase()) {
      case 'facebook':
        return Icons.facebook; // Ví dụ icon
      case 'instagram':
        return Icons.camera_alt; // Ví dụ icon
      case 'youtube':
        return Icons.play_circle_fill; // Ví dụ icon
      case 'tiktok':
        return Icons.music_note; // Ví dụ icon
      case 'twitter':
        return Icons.chat; // Ví dụ icon
      case 'zalo':
        return Icons.message; // Ví dụ icon
      // Thêm các case khác cho các ứng dụng phổ biến nếu cần
      default:
        return Icons.apps; // Icon mặc định
    }
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
                    colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Settings, và nút kiểm tra quyền
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Thêm chức năng đăng xuất cho nút cài đặt
                                  _showSettingsMenu(context);
                                },
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                              ),
                              // Nút kiểm tra quyền
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const PermissionSetupScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                tooltip: 'Kiểm tra quyền',
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
                              child:
                                  _isLoadingProfile
                                      ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ) // Hiển thị loading cho avatar
                                      : _profileImage != null
                                      ? Image.file(
                                        _profileImage!,
                                        fit: BoxFit.cover,
                                      )
                                      : _avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty
                                      ? Image.network(
                                        // Hiển thị avatar từ URL nếu có
                                        _avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          print(
                                            "Error loading network avatar: $error",
                                          );
                                          return Image.asset(
                                            'assets/avatar.jpg',
                                            fit: BoxFit.cover,
                                          ); // Fallback nếu lỗi tải URL
                                        },
                                        loadingBuilder: (
                                          BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        // Fallback cuối cùng nếu không có local và URL
                                        'assets/avatar.jpg',
                                        fit: BoxFit.cover,
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

                    // Usage chart card (Thay thế nội dung biểu đồ cột bằng biểu đồ tròn)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child:
                          _buildPieChartSection(), // Gọi widget hiển thị biểu đồ tròn
                    ),

                    // Bottom navigation padding
                    SizedBox(height: size.height * 0.06),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                title: Text(
                  'Đăng xuất',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
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
          title: Text(
            'Đăng xuất',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Đăng xuất',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
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

      await widget.authService
          .signOut(); // Use AuthService to sign out from Supabase

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
          content: Text(
            'Có lỗi xảy ra khi đăng xuất',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
