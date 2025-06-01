import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_blocking_service.dart';
import '../settings/permission_setup_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:table_calendar/table_calendar.dart' as table_calendar;

class BlockedAppScreen extends StatefulWidget {
  const BlockedAppScreen({super.key});

  @override
  State<BlockedAppScreen> createState() => _BlockedAppScreenState();
}

class _BlockedAppScreenState extends State<BlockedAppScreen>
    with
        WidgetsBindingObserver // Thêm WidgetsBindingObserver
        {
  // Lưu trữ dữ liệu các ứng dụng bị chặn
  late List<Map<String, dynamic>> _blockedApps = [];

  // Lưu trữ dữ liệu theo dõi thời gian sử dụng
  final Map<String, int> _appUsageTime = {};

  // Lưu trữ danh sách các ứng dụng đang chạy
  final Map<String, bool> _isAppRunning = {};

  // Theo dõi các ứng dụng đã được chặn để tránh spam
  final Map<String, bool> _appAlreadyBlocked = {};

  // Theo dõi thời gian log cuối cùng để tránh spam log
  final Map<String, DateTime> _lastLogTime = {};

  // Timer để theo dõi thời gian sử dụng ứng dụng
  Timer? _usageTimer;

  // Định kỳ lưu dữ liệu
  Timer? _saveDataTimer;

  // Lưu trữ ngày cuối cùng dữ liệu usage được tải
  DateTime? _lastUsageLoadDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Thêm observer
    _loadBlockedApps();
    _startUsageTracking();
    _checkPermissions(); // Add permission check

    // Lưu dữ liệu định kỳ mỗi 1 phút
    _saveDataTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _saveUsageData();
    });

    // Ghi lại ngày tải dữ liệu usage ban đầu
    _lastUsageLoadDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Gỡ observer
    _usageTimer?.cancel();
    _saveDataTimer?.cancel();
    _saveUsageData(); // Lưu dữ liệu trước khi đóng màn hình

    // Stop the blocking service if no apps are being blocked
    final hasBlockedApps = _blockedApps.any((app) => app['isBlocked'] == true);
    if (!hasBlockedApps) {
      AppBlockingService.stopAppBlockingService();
    }

    super.dispose();
  }

  // Implement didChangeAppLifecycleState to check for date change and reload data
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi ứng dụng trở lại trạng thái hoạt động, kiểm tra ngày
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastLoadedDay =
          _lastUsageLoadDate != null
              ? DateTime(
                _lastUsageLoadDate!.year,
                _lastUsageLoadDate!.month,
                _lastUsageLoadDate!.day,
              )
              : null;

      if (lastLoadedDay == null ||
          !table_calendar.isSameDay(today, lastLoadedDay)) {
        print(
          'Date changed or no data loaded, reloading usage data and resetting blocking state...',
        );
        _loadRealUsageData(); // Tải lại dữ liệu usage cho ngày mới
        _lastUsageLoadDate = today; // Cập nhật ngày tải dữ liệu cuối cùng

        // Reset trạng thái blocking nếu cần thiết (để đảm bảo chặn lại đúng ngày)
        // Có thể cần thêm phương thức trong AppBlockingService để reset trạng thái blocking theo ngày
        // Hiện tại, logic _checkRunningApps sẽ tự kiểm tra và áp dụng lại blocking nếu vượt limit mới của ngày
        // Nhưng để chắc chắn, có thể cần một lệnh rõ ràng hơn cho native code.
        // Tạm thời chỉ cần tải lại dữ liệu usage.
      } else {
        print(
          'Date is the same, no need to reload usage data in BlockedAppScreen.',
        );
      }
    }
  }

  // Tải danh sách ứng dụng bị chặn từ bộ nhớ
  Future<void> _loadBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedAppsJson = prefs.getStringList('blocked_apps') ?? [];
    final usageTimeJson = prefs.getStringList('app_usage_time') ?? [];

    setState(() {
      if (blockedAppsJson.isNotEmpty) {
        _blockedApps =
            blockedAppsJson.map((jsonString) {
              Map<String, dynamic> appData = json.decode(jsonString);

              // Chuyển đổi màu sắc từ JSON sang Color
              if (appData['color'] is String) {
                String colorString = appData['color'];
                int colorValue = int.parse(colorString.replaceAll('#', '0xFF'));
                appData['color'] = Color(colorValue);
              }

              return appData;
            }).toList();
      } else {
        // Khởi tạo danh sách rỗng khi chưa có dữ liệu được lưu trữ
        _blockedApps = [];
      }

      // Tải dữ liệu thời gian sử dụng
      if (usageTimeJson.isNotEmpty) {
        for (String jsonString in usageTimeJson) {
          Map<String, dynamic> usageData = json.decode(jsonString);
          String packageName = usageData['packageName'];
          int seconds = usageData['seconds'];
          _appUsageTime[packageName] = seconds;
        }
      }
    });

    // Load real usage data from system after loading blocked apps
    await _loadRealUsageData();
  }

  // Load real usage data from Android Usage Stats API
  Future<void> _loadRealUsageData() async {
    try {
      final permissions = await AppBlockingService.checkAllPermissions();

      if (permissions['usageStats'] == true) {
        // Lấy dữ liệu sử dụng thực tế cho NGÀY HIỆN TẠI
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final allAppsUsage = await AppBlockingService.getUsageTimeForDateRange(
          startOfToday,
          endOfToday,
        );

        // Reset _appUsageTime cho ngày mới trước khi cập nhật
        _appUsageTime.clear();

        // Update usage time for our blocked apps with real data
        for (var app in _blockedApps) {
          String packageName = app['packageName'];
          if (allAppsUsage.containsKey(packageName)) {
            _appUsageTime[packageName] = allAppsUsage[packageName]!;
          }
        }

        // Save updated usage data
        await _saveUsageData();

        // Update UI
        if (mounted) {
          setState(() {});
        }

        print('Real usage data loaded successfully for today');
      } else {
        print('Usage Stats permission not granted, using saved data');
      }
    } catch (e) {
      print('Error loading real usage data: $e');
    }
  }

  // Lưu danh sách ứng dụng bị chặn vào bộ nhớ
  Future<void> _saveBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();

    // Chuyển đổi danh sách ứng dụng thành định dạng JSON để lưu trữ
    final blockedAppsJson =
        _blockedApps.map((app) {
          // Tạo bản sao để tránh thay đổi dữ liệu gốc
          Map<String, dynamic> appCopy = Map<String, dynamic>.from(app);

          // Chuyển đổi Color sang chuỗi hex
          if (appCopy['color'] is Color) {
            Color color = appCopy['color'] as Color;
            appCopy['color'] =
                '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
          }

          return json.encode(appCopy);
        }).toList();

    await prefs.setStringList('blocked_apps', blockedAppsJson);
  }

  // Lưu dữ liệu thời gian sử dụng
  Future<void> _saveUsageData() async {
    final prefs = await SharedPreferences.getInstance();

    // Chuyển đổi dữ liệu thời gian sử dụng thành định dạng JSON để lưu trữ
    final usageTimeJson =
        _appUsageTime.entries.map((entry) {
          return json.encode({
            'packageName': entry.key,
            'seconds': entry.value,
          });
        }).toList();

    await prefs.setStringList('app_usage_time', usageTimeJson);
  }

  // Bắt đầu theo dõi thời gian sử dụng ứng dụng
  void _startUsageTracking() {
    // Theo dõi mỗi giây
    _usageTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkRunningApps();
    });
  }

  // Kiểm tra các ứng dụng đang chạy và cập nhật thời gian sử dụng thực tế
  Future<void> _checkRunningApps() async {
    try {
      // Lấy thời gian sử dụng thực tế từ Usage Stats API
      final allAppsUsage = await AppBlockingService.getAllAppsUsageTime();

      for (var app in _blockedApps) {
        String packageName = app['packageName'];

        // CRITICAL SAFETY CHECK: Never process our own app
        if (packageName == 'com.example.smartmanagementapp') {
          print('SAFETY: Skipping our own app from blocking logic');
          continue;
        }

        // Cập nhật thời gian sử dụng thực tế từ system
        int realUsageSeconds = allAppsUsage[packageName] ?? 0;
        _appUsageTime[packageName] = realUsageSeconds;

        // Kiểm tra xem app có đang chạy không
        bool isCurrentlyRunning =
            await AppBlockingService.isAppCurrentlyRunning(packageName);
        _isAppRunning[packageName] = isCurrentlyRunning;

        // Kiểm tra nếu đã đạt giới hạn thời gian và app đang được bật blocking
        int limitSeconds = app['timeLimit'] * 60;

        if (app['isBlocked'] && realUsageSeconds >= limitSeconds) {
          // Kiểm tra xem app đã được chặn chưa để tránh spam
          bool alreadyBlocked = _appAlreadyBlocked[packageName] ?? false;
          DateTime? lastLog = _lastLogTime[packageName];
          DateTime now = DateTime.now();

          // Chỉ thực hiện blocking và log nếu:
          // 1. App chưa được chặn trước đó, HOẶC
          // 2. Đã qua ít nhất 30 giây từ lần log cuối cùng
          bool shouldBlock = !alreadyBlocked;
          bool shouldLog =
              lastLog == null || now.difference(lastLog).inSeconds >= 30;

          if (shouldLog) {
            print(
              'App ${app['name']} has exceeded limit: ${realUsageSeconds}s >= ${limitSeconds}s',
            );
            _lastLogTime[packageName] = now;
          }

          if (shouldBlock) {
            print(
              'BLOCKING: First time blocking ${app['name']} due to limit exceeded',
            );
            _appAlreadyBlocked[packageName] = true;
            await _blockApp(app);
          }
        } else {
          // App chưa đạt giới hạn hoặc không được bật blocking, reset trạng thái
          _appAlreadyBlocked[packageName] = false;
        }
      }

      // Lưu dữ liệu usage mới
      await _saveUsageData();

      // Cập nhật UI để hiển thị thời gian sử dụng mới
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking running apps: $e');
      // Fallback to previous behavior if there's an error
    }
  }

  // Thực hiện chặn ứng dụng khi đạt đến giới hạn thời gian
  Future<void> _blockApp(Map<String, dynamic> app) async {
    // Check if app blocking service is properly set up
    final permissions = await AppBlockingService.checkAllPermissions();

    if (!permissions['accessibility']! ||
        !permissions['usageStats']! ||
        !permissions['overlay']!) {
      // Show permission setup dialog
      _showPermissionSetupDialog();
      return;
    }

    // Start the app blocking service if not already running
    await AppBlockingService.startAppBlockingService();

    // Hiển thị cảnh báo khi ứng dụng bị chặn
    _showBlockingAlert(app);
  }

  // Hiển thị cảnh báo khi ứng dụng bị chặn
  void _showBlockingAlert(Map<String, dynamic> app) {
    // Hiển thị thông báo chỉ khi ứng dụng bị chặn lần đầu tiên trong ngày
    // hoặc khi người dùng cố gắng mở ứng dụng sau khi đã vượt quá giới hạn

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Ứng dụng bị chặn',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bạn đã sử dụng "${app['name']}" quá thời gian cho phép hôm nay (${app['timeLimit']} phút).',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thử lại vào ngày mai hoặc thay đổi giới hạn thời gian.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Đã hiểu',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAppSettingsDialog(app);
                },
                child: Text(
                  'Thay đổi giới hạn',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            ],
          ),
    );
  }

  // Lấy thời gian sử dụng ứng dụng theo phút
  int _getAppUsageMinutes(String packageName) {
    int seconds = _appUsageTime[packageName] ?? 0;
    return (seconds / 60).round();
  }

  // Kiểm tra xem ứng dụng có đang vượt quá giới hạn không
  bool _isAppOverLimit(Map<String, dynamic> app) {
    if (!app['isBlocked']) return false;

    int usageMinutes = _getAppUsageMinutes(app['packageName']);
    return usageMinutes >= app['timeLimit'];
  }

  int get _blockedAppsCount =>
      _blockedApps.where((app) => app['isBlocked']).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề trang
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GIỚI HẠN THỜI GIAN',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Permission warning banner
            FutureBuilder<Map<String, bool>>(
              future: AppBlockingService.checkAllPermissions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final permissions = snapshot.data!;
                final allGranted = permissions.values.every(
                  (granted) => granted,
                );

                if (allGranted) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cần cấp quyền để chặn ứng dụng',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Nhấn icon ⚙️ phía trên để cấp quyền',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const PermissionSetupScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Cấp ngay',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Mô tả
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Đặt giới hạn thời gian cho các ứng dụng để tập trung vào công việc',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Thông báo ứng dụng đang bị khóa
            _buildLockedAppsNotification(),

            // Tiêu đề danh sách ứng dụng
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách ứng dụng',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddAppDialog,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Thêm ứng dụng',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Danh sách ứng dụng hoặc thông báo trống
            Expanded(
              child:
                  _blockedApps.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        itemCount: _blockedApps.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          final app = _blockedApps[index];
                          return _buildAppListItem(app);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget thông báo ứng dụng đang bị khóa
  Widget _buildLockedAppsNotification() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFECDCD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, color: Color(0xFFFF5C5C), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_blockedAppsCount ứng dụng đang quản lý',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Nhấp vào ứng dụng để cài đặt thời gian',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFE53935).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget hiển thị trạng thái trống khi chưa có ứng dụng nào được giới hạn
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Chưa có Ứng dụng nào được giới hạn thời gian',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Thêm ứng dụng để quản lý',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _showAddAppDialog();
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Thêm ứng dụng',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị từng ứng dụng trong danh sách
  Widget _buildAppListItem(Map<String, dynamic> app) {
    // Lấy thời gian sử dụng của ứng dụng
    final String packageName = app['packageName'] ?? '';
    final int usageMinutes = _getAppUsageMinutes(packageName);
    final int limitMinutes = app['timeLimit'] ?? 30;
    final double usagePercentage =
        limitMinutes > 0 ? (usageMinutes / limitMinutes).clamp(0.0, 1.0) : 0.0;
    final bool isOverLimit = _isAppOverLimit(app);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // App icon
                _buildAppIcon(app),
                const SizedBox(width: 16),

                // App details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOverLimit)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Vượt giới hạn',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giới hạn: ${app['timeLimit']} phút mỗi ngày',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings button
                IconButton(
                  onPressed: () => _showAppSettingsDialog(app),
                  icon: Icon(Icons.settings, color: Colors.grey[400], size: 20),
                ),

                // Switch toggle
                Switch(
                  value: app['isBlocked'],
                  onChanged: (value) {
                    setState(() {
                      app['isBlocked'] = value;

                      // Reset tracking when blocking state changes
                      String packageName = app['packageName'];
                      _appAlreadyBlocked[packageName] = false;
                      _lastLogTime.remove(packageName);

                      _saveBlockedApps();
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  activeTrackColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.5),
                ),
              ],
            ),
          ),

          // Hiển thị thanh tiến trình sử dụng
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã dùng: $usageMinutes phút',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isOverLimit ? Colors.red : Colors.grey[600],
                        fontWeight:
                            isOverLimit ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      'Còn lại: ${(limitMinutes - usageMinutes).clamp(0, limitMinutes)} phút',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: usagePercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverLimit
                          ? Colors.red
                          : usagePercentage > 0.8
                          ? Colors.orange
                          : Theme.of(context).primaryColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị icon của ứng dụng
  Widget _buildAppIcon(Map<String, dynamic> app) {
    // Fallback icon khi không tìm thấy file icon
    Widget fallbackIcon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: app['color'].withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_getIconForApp(app['name']), color: app['color'], size: 24),
    );

    // Nếu có đường dẫn icon, hiển thị từ asset, nếu không dùng fallback
    return app['icon'] is String
        ? Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              app['icon'],
              errorBuilder: (context, error, stackTrace) => fallbackIcon,
            ),
          ),
        )
        : fallbackIcon;
  }

  // Helper function để lấy icon phù hợp với tên ứng dụng
  IconData _getIconForApp(String appName) {
    switch (appName.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'tiktok':
        return Icons.music_note;
      case 'twitter':
        return Icons.chat;
      default:
        return Icons.apps;
    }
  }

  void _showAddAppDialog() {
    String searchQuery = '';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Thêm ứng dụng mới',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Tìm kiếm ứng dụng',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      width: double.maxFinite,
                      child: FutureBuilder<List<AppInfo>>(
                        future: InstalledApps.getInstalledApps(true, true),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Lỗi khi tải ứng dụng: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Không có ứng dụng nào'),
                            );
                          } else {
                            final List<AppInfo> filteredApps =
                                searchQuery.isEmpty
                                    ? snapshot.data!
                                        .where(
                                          (app) =>
                                              app.packageName !=
                                                  'com.example.smartmanagementapp' &&
                                              !app.packageName.startsWith(
                                                'com.android',
                                              ) &&
                                              !app.packageName.startsWith(
                                                'android',
                                              ),
                                        )
                                        .toList()
                                    : snapshot.data!
                                        .where(
                                          (app) =>
                                              app.name.toLowerCase().contains(
                                                searchQuery,
                                              ) &&
                                              app.packageName !=
                                                  'com.example.smartmanagementapp' &&
                                              !app.packageName.startsWith(
                                                'com.android',
                                              ) &&
                                              !app.packageName.startsWith(
                                                'android',
                                              ),
                                        )
                                        .toList();

                            if (filteredApps.isEmpty) {
                              return Center(
                                child: Text(
                                  'Không tìm thấy ứng dụng phù hợp',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = filteredApps[index];
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      app.icon!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.apps,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                  title: Text(
                                    app.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    app.packageName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    // SAFETY CHECK: Never allow adding our own app
                                    if (app.packageName ==
                                        'com.example.smartmanagementapp') {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Không thể thêm chính ứng dụng này vào danh sách chặn',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    final color = _getColorForApp(app.name);

                                    // Lưu ứng dụng mới vào danh sách
                                    setState(() {
                                      _blockedApps.add({
                                        'name': app.name,
                                        'packageName': app.packageName,
                                        'icon':
                                            null, // Không lưu icon vì quá lớn
                                        'color': color,
                                        'timeLimit': 30, // Mặc định 30 phút
                                        'isBlocked': true,
                                        'blockedTime': const [],
                                      });
                                      _appUsageTime[app.packageName] =
                                          0; // Khởi tạo thời gian sử dụng
                                      _saveBlockedApps(); // Lưu thay đổi ngay lập tức
                                    });

                                    Navigator.pop(context); // Đóng hộp thoại

                                    // Hiển thị thông báo đã thêm thành công
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã thêm ${app.name} vào danh sách theo dõi',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Hàm để tạo màu cho ứng dụng dựa trên tên
  Color _getColorForApp(String appName) {
    final Map<String, Color> knownAppColors = {
      'facebook': const Color(0xFF1877F2),
      'instagram': const Color(0xFFE4405F),
      'youtube': const Color(0xFFFF0000),
      'tiktok': const Color(0xFF000000),
      'twitter': const Color(0xFF1DA1F2),
      'netflix': const Color(0xFFE50914),
      'spotify': const Color(0xFF1ED760),
      'whatsapp': const Color(0xFF25D366),
      'telegram': const Color(0xFF0088CC),
      'messenger': const Color(0xFF00B2FF),
      'line': const Color(0xFF00C300),
      'discord': const Color(0xFF5865F2),
      'snapchat': const Color(0xFFFFFC00),
      'pinterest': const Color(0xFFE60023),
    };

    // Tìm từ khóa trùng với tên ứng dụng
    String? matchingKey = knownAppColors.keys.firstWhere(
      (key) => appName.toLowerCase().contains(key),
      orElse: () => '',
    );

    if (matchingKey.isNotEmpty) {
      return knownAppColors[matchingKey]!;
    }

    // Nếu không tìm thấy, tạo màu ngẫu nhiên dựa trên tên ứng dụng
    int hashCode = appName.hashCode;
    final colors = [
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

    return colors[hashCode.abs() % colors.length];
  }

  void _showAppSettingsDialog(Map<String, dynamic> app) {
    int timeLimit = app['timeLimit'];
    List<Map<String, dynamic>> schedules = List<Map<String, dynamic>>.from(
      app['schedules'] ?? [],
    );

    // Nếu chưa có lịch trình nào, tạo một lịch trình mặc định
    if (schedules.isEmpty) {
      schedules.add({
        'startTime': '08:00',
        'endTime': '17:00',
        'days': [1, 2, 3, 4, 5], // Thứ 2 - Thứ 6
        'active': false,
      });
    }

    // Phân loại ứng dụng
    final List<String> categories = [
      'Mạng xã hội',
      'Giải trí',
      'Trò chơi',
      'Công việc',
      'Học tập',
      'Khác',
      'Chưa phân loại',
    ];
    String category = app['category'] ?? 'Chưa phân loại';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cài đặt cho ${app['name']}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 20,
                            ),
                          ],
                        ),
                        const Divider(),

                        // Phần giới hạn thời gian
                        Text(
                          'Giới hạn thời gian sử dụng:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: timeLimit.toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          label: '$timeLimit phút',
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            setState(() {
                              timeLimit = value.round();
                            });
                          },
                        ),
                        Center(
                          child: Text(
                            '$timeLimit phút mỗi ngày',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phần phân loại ứng dụng
                        Text(
                          'Phân loại ứng dụng:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: category,
                              items:
                                  categories.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  category = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phần lịch trình chặn
                        Text(
                          'Lịch trình chặn:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Danh sách lịch trình
                        ...schedules.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> schedule = entry.value;
                          bool isActive = schedule['active'] ?? false;
                          List<int> days = List<int>.from(schedule['days']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Lịch trình ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Switch(
                                      value: isActive,
                                      onChanged: (value) {
                                        setState(() {
                                          schedule['active'] = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeField(
                                        'Bắt đầu:',
                                        schedule['startTime'],
                                        (newTime) {
                                          setState(() {
                                            schedule['startTime'] = newTime;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimeField(
                                        'Kết thúc:',
                                        schedule['endTime'],
                                        (newTime) {
                                          setState(() {
                                            schedule['endTime'] = newTime;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Áp dụng cho ngày:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children:
                                      [
                                        'T2',
                                        'T3',
                                        'T4',
                                        'T5',
                                        'T6',
                                        'T7',
                                        'CN',
                                      ].asMap().entries.map((e) {
                                        int dayIndex = e.key + 1;
                                        bool isSelected = days.contains(
                                          dayIndex,
                                        );
                                        return _buildDaySelection(
                                          e.value,
                                          isSelected,
                                          () {
                                            setState(() {
                                              if (isSelected) {
                                                days.remove(dayIndex);
                                              } else {
                                                days.add(dayIndex);
                                              }
                                              schedule['days'] = days;
                                            });
                                          },
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Nút thêm lịch trình mới
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(
                              'Thêm lịch trình',
                              style: GoogleFonts.poppins(),
                            ),
                            onPressed: () {
                              setState(() {
                                schedules.add({
                                  'startTime': '08:00',
                                  'endTime': '17:00',
                                  'days': [1, 2, 3, 4, 5],
                                  'active': false,
                                });
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Nút xóa ứng dụng khỏi danh sách
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              // Hiển thị hộp thoại xác nhận trước khi xóa
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        'Xóa khỏi danh sách',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Bạn có chắc chắn muốn xóa ${app['name']} khỏi danh sách giới hạn không?',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text(
                                            'Hủy',
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Xóa ứng dụng khỏi danh sách và cập nhật
                                            _blockedApps.removeWhere(
                                              (a) =>
                                                  a['packageName'] ==
                                                  app['packageName'],
                                            );
                                            _saveBlockedApps();

                                            // Đóng hai hộp thoại
                                            Navigator.pop(
                                              context,
                                            ); // Đóng hộp thoại xác nhận
                                            Navigator.pop(
                                              context,
                                            ); // Đóng hộp thoại cài đặt

                                            // Cập nhật UI
                                            setState(() {});
                                          },
                                          child: Text(
                                            'Xóa',
                                            style: GoogleFonts.poppins(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: Text(
                              'Xóa khỏi danh sách',
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Các nút hành động
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Hủy', style: GoogleFonts.poppins()),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Cập nhật thông tin cài đặt
                                int appIndex = _blockedApps.indexWhere(
                                  (a) => a['packageName'] == app['packageName'],
                                );
                                if (appIndex >= 0) {
                                  _blockedApps[appIndex]['timeLimit'] =
                                      timeLimit;
                                  _blockedApps[appIndex]['category'] = category;
                                  _blockedApps[appIndex]['schedules'] =
                                      schedules;
                                  _saveBlockedApps();
                                }
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Lưu', style: GoogleFonts.poppins()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildTimeField(
    String label,
    String initialValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDaySelection(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // Check required permissions for app blocking
  Future<void> _checkPermissions() async {
    final permissions = await AppBlockingService.checkAllPermissions();

    if (!permissions['accessibility']! ||
        !permissions['usageStats']! ||
        !permissions['overlay']!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionSetupDialog();
      });
    } else {
      // Start the app blocking service if all permissions are granted
      await AppBlockingService.startAppBlockingService();
    }
  }

  // Show permission setup dialog
  void _showPermissionSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Cần cấp quyền',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Để chặn ứng dụng hiệu quả, bạn cần cấp các quyền sau:',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  'Accessibility Service',
                  'Để theo dõi và chặn ứng dụng',
                  Icons.accessibility,
                ),
                _buildPermissionItem(
                  'Usage Stats',
                  'Để xem thời gian sử dụng ứng dụng',
                  Icons.bar_chart,
                ),
                _buildPermissionItem(
                  'Overlay Permission',
                  'Để hiển thị màn hình chặn',
                  Icons.layers,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Để sau',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _requestPermissions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(
                  'Cấp quyền',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // Build permission item widget
  Widget _buildPermissionItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Request all required permissions
  Future<void> _requestPermissions() async {
    final permissions = await AppBlockingService.checkAllPermissions();

    if (!permissions['accessibility']!) {
      await AppBlockingService.requestAccessibilityPermission();
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Wait for settings to open
    }

    if (!permissions['usageStats']!) {
      await AppBlockingService.requestUsageStatsPermission();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!permissions['overlay']!) {
      await AppBlockingService.requestOverlayPermission();
      await Future.delayed(const Duration(seconds: 1));
    }

    // Show snackbar with instructions
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng bật các quyền cần thiết và quay lại ứng dụng',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
