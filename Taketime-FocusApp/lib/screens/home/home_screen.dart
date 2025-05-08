import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../plan/plan_detail_screen.dart';
import '../../services/auth_service.dart'; // Import AuthService

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

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Gọi hàm lấy dữ liệu người dùng khi widget được khởi tạo
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return; // Kiểm tra widget còn trong tree không
    setState(() {
      _isLoadingProfile = true; // Bắt đầu tải, hiển thị loading
    });

    final userProfile = await _authService.fetchUserProfile();

    if (!mounted) return; // Kiểm tra lại sau khi await

    setState(() {
      if (userProfile != null) {
        // Cập nhật tên và avatar từ dữ liệu lấy được
        _userName = userProfile['full_name'] ?? userProfile['username'] ?? "Người dùng";
        _avatarUrl = userProfile['avatar_url'];
        print("HomeScreen: User profile loaded: Name: $_userName, Avatar: $_avatarUrl");
      } else {
        _userName = "Người dùng"; // Giá trị mặc định nếu không lấy được
        _avatarUrl = null;
        print("HomeScreen: Failed to load user profile.");
      }
      _isLoadingProfile = false; // Kết thúc tải
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planProvider = Provider.of<PlanProvider>(context);
    // final todayPlans = planProvider.getTodayPlans();

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
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                        )
                      : _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(_avatarUrl!),
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Error loading avatar in HomeScreen: $exception');
                                // Có thể hiển thị một icon mặc định ở đây nếu muốn
                              },
                            )
                          : CircleAvatar( // Fallback avatar
                              radius: 24,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                  const SizedBox(width: 16),
                  // Hiển thị Tên người dùng
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
                              _userName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Search Bar (Placeholder)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.search,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm công việc...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[700],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
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
                      'Thống kê hôm nay',
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
                            Icons.schedule,
                            '3.5 giờ',
                            'Thời gian sử dụng',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.block,
                            '7 lần',
                            'Ứng dụng bị chặn',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.self_improvement,
                            '2 phiên',
                            'Tập trung',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.emoji_events,
                            '85%',
                            'Hiệu suất',
                          ),
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
                  final todayPlans = planProvider.getPlansForDate(DateTime.now());
                  
                  if (todayPlans.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
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
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = todayPlans[index];
                      final priorityColor = plan.getPriorityColor();
                      
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => PlanDetailScreen(plan: plan))
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
                                color: isDark 
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
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: plan.isCompleted 
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
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${plan.startTime.hour.toString().padLeft(2, '0')}:${plan.startTime.minute.toString().padLeft(2, '0')} - ${plan.endTime.hour.toString().padLeft(2, '0')}:${plan.endTime.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  
  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
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