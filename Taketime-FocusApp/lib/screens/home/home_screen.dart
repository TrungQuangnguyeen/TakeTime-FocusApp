import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../plan/plan_detail_screen.dart';
import '../../services/auth_service.dart'; // Import AuthService
import '../../services/focus_mode_service.dart'; // Import FocusModeService
import '../../providers/user_provider.dart'; // Import UserProvider
import 'dart:math'; // Import dart:math

// Chuyển HomeScreen thành StatefulWidget để quản lý trạng thái
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "Đang tải..."; // Biến trạng thái cho tên người dùng
  String? _avatarUrl; // Biến trạng thái cho URL avatar
  bool _isLoadingProfile = true; // Biến trạng thái cho việc tải dữ liệu
  final AuthService _authService = AuthService(); // Khởi tạo AuthService

  // Thêm state variables cho thống kê focus mode
  int _totalFocusSessions = 0;
  int _completedFocusSessions = 0;
  int _totalCompletedFocusDurationMinutes = 0;
  bool _isLoadingFocusStats = true; // Biến trạng thái cho việc tải thống kê

  // Danh sách các lời chúc ngẫu nhiên
  final List<String> _randomMessages = [
    'Chúc bạn một ngày làm việc hiệu quả!',
    'Tập trung cao độ để đạt mục tiêu nhé!',
    'Hãy biến hôm nay thành một ngày tuyệt vời!',
    'Luôn giữ năng lượng tích cực nha!',
    'Mọi nỗ lực của bạn sẽ được đền đáp!',
    'Một ngày mới, những cơ hội mới!',
    'Bạn đang làm rất tốt!',
  ];

  // Biến trạng thái cho lời chúc ngẫu nhiên
  String _currentRandomMessage = '';

  // Biến trạng thái chung cho việc tải dữ liệu ban đầu
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Gọi hàm lấy dữ liệu người dùng khi widget được khởi tạo
    _fetchDailyFocusStats(); // Gọi hàm lấy thống kê focus mode
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return; // Kiểm tra widget còn trong tree không
    // Không cần setState ở đây ngay lập tức, sẽ cập nhật trạng thái chung sau

    final userProfile = await _authService.fetchUserProfile();

    if (!mounted) return; // Kiểm tra lại sau khi await

    setState(() {
      if (userProfile != null) {
        // Cập nhật tên và avatar từ dữ liệu lấy được
        _userName =
            userProfile['full_name'] ?? userProfile['username'] ?? "Người dùng";
        _avatarUrl = userProfile['avatar_url'];
        print(
          "HomeScreen: User profile loaded: Name: $_userName, Avatar: $_avatarUrl",
        );

        // Chọn một lời chúc ngẫu nhiên
        final randomIndex = Random().nextInt(_randomMessages.length);
        _currentRandomMessage = _randomMessages[randomIndex];
      } else {
        _userName = "Người dùng"; // Giá trị mặc định nếu không lấy được
        _avatarUrl = null;
        print("HomeScreen: Failed to load user profile.");
        _currentRandomMessage =
            'Hãy bắt đầu một ngày mới!'; // Lời chúc mặc định
      }
      _isLoadingProfile = false; // Kết thúc tải profile
      // Kiểm tra xem các phần khác đã tải xong chưa để tắt trạng thái loading chung
      if (!_isLoadingFocusStats) {
        _isDataLoading = false;
      }
    });
  }

  Future<void> _fetchDailyFocusStats() async {
    if (!mounted) return;
    // Không cần setState ở đây ngay lập tức, sẽ cập nhật trạng thái chung sau

    final focusModeService = FocusModeService(
      // Cần UserProvider để lấy baseUrl và accessToken
      baseUrl: Provider.of<UserProvider>(context, listen: false).baseUrl,
      accessToken:
          Provider.of<UserProvider>(
            context,
            listen: false,
          ).headers['Authorization']?.replaceFirst('Bearer ', '') ??
          '',
    );

    final stats = await focusModeService.getDailyFocusStats();

    if (!mounted) return;

    debugPrint('DEBUG: DailyFocusStats received: $stats');

    setState(() {
      if (stats != null) {
        _totalFocusSessions = stats.totalSessions;
        _completedFocusSessions = stats.completedSessions;
        _totalCompletedFocusDurationMinutes =
            stats.totalCompletedDurationMinutes;
      }
      _isLoadingFocusStats = false; // Kết thúc tải stats
      // Kiểm tra xem các phần khác đã tải xong chưa để tắt trạng thái loading chung
      if (!_isLoadingProfile) {
        _isDataLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planProvider = Provider.of<PlanProvider>(context);

    // Hiển thị màn hình loading nếu dữ liệu đang được tải
    if (_isDataLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Hiển thị nội dung màn hình chính sau khi dữ liệu đã tải xong
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with User Info
              Row(
                children: [
                  // Hiển thị Avatar
                  _isLoadingProfile
                      ? CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.2,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                      : _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(_avatarUrl!),
                        onBackgroundImageError: (exception, stackTrace) {
                          print(
                            'Error loading avatar in HomeScreen: $exception',
                          );
                          // Có thể hiển thị một icon mặc định ở đây nếu muốn
                        },
                      )
                      : CircleAvatar(
                        // Fallback avatar
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.2,
                        ),
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                  const SizedBox(width: 16),
                  // Hiển thị Tên người dùng và lời chúc ngẫu nhiên
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      _isLoadingProfile
                          ? Text(
                            "Đang tải...",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          )
                          : Text(
                            _userName, // Hiển thị tên người dùng
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                      // Hiển thị lời chúc ngẫu nhiên
                      if (!_isLoadingProfile &&
                          _currentRandomMessage.isNotEmpty)
                        Text(
                          _currentRandomMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống kê ngày hôm nay',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.watch_later_outlined, // Icon cho số phiên
                            _isLoadingFocusStats
                                ? '--'
                                : _totalFocusSessions
                                    .toString(), // Hiển thị số phiên hoặc placeholder
                            'Phiên tập trung', // Label: Phiên tập trung
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons
                                .access_time_outlined, // Icon cho tổng thời gian
                            _isLoadingFocusStats
                                ? '-- phút'
                                : '${_totalCompletedFocusDurationMinutes} phút', // Hiển thị tổng thời gian hoặc placeholder
                            'Thời gian hoàn thành', // Label: Tổng thời gian
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.military_tech_outlined, // Icon cho hiệu suất
                            _isLoadingFocusStats
                                ? '--%'
                                : _totalFocusSessions > 0
                                ? '${((_completedFocusSessions / _totalFocusSessions) * 100).toStringAsFixed(0)}%'
                                : '0%', // Tính toán và hiển thị hiệu suất
                            'Hiệu suất hoàn thành', // Label: Hiệu suất hoàn thành
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              Container(), // Có thể để trống hoặc xóa Expanded này
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Features section
              Text(
                'Công việc hôm nay',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Danh sách công việc của ngày hôm nay
              Consumer<PlanProvider>(
                builder: (context, planProvider, child) {
                  final todayPlans = planProvider.getPlansForDate(
                    DateTime.now(),
                  );

                  if (todayPlans.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có công việc nào cho hôm nay',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayPlans.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = todayPlans[index];
                      final priorityColor = plan.getPriorityColor();

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PlanDetailScreen(plan: plan),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                plan.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color:
                                              isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${plan.startTime.hour.toString().padLeft(2, '0')}:${plan.startTime.minute.toString().padLeft(2, '0')} - ${plan.endTime.hour.toString().padLeft(2, '0')}:${plan.endTime.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: plan.getStatusColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  plan.getStatusText(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: plan.getStatusColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
