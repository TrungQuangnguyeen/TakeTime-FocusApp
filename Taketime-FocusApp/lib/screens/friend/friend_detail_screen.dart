import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class FriendDetailScreen extends StatelessWidget {
  final String userId;
  
  const FriendDetailScreen({
    super.key,
    required this.userId,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserById(userId);
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết người dùng'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Không tìm thấy thông tin người dùng'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(user.avatarUrl),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${user.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Thống kê người dùng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    context,
                    '${user.daysUsed}',
                    'Ngày sử dụng',
                    theme.colorScheme.primary,
                  ),
                  _buildStatItem(
                    context,
                    '${user.achievements}',
                    'Thành tích',
                    theme.colorScheme.secondary,
                  ),
                  _buildStatItem(
                    context,
                    '${user.efficiency.toInt()}%',
                    'Hiệu suất',
                    _getEfficiencyColor(user.efficiency),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Biểu đồ hoạt động
            _buildActivityGraph(context, theme),
            
            const SizedBox(height: 40),
            
            // Danh sách thành tựu gần đây (mô phỏng)
            _buildRecentAchievements(context, theme),
            
            const SizedBox(height: 32),
            
            // Nút hành động
            _buildActionButtons(context, user, userProvider),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, 
    String value, 
    String label, 
    Color color
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityGraph(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Hoạt động gần đây',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          height: 200,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thời gian tập trung hàng tuần',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBar(context, 'T2', 0.6, theme),
                    _buildBar(context, 'T3', 0.45, theme),
                    _buildBar(context, 'T4', 0.65, theme),
                    _buildBar(context, 'T5', 0.85, theme),
                    _buildBar(context, 'T6', 0.5, theme),
                    _buildBar(context, 'T7', 0.7, theme),
                    _buildBar(context, 'CN', 0.8, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBar(BuildContext context, String day, double value, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 100 * value,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildRecentAchievements(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Thành tựu gần đây',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: 3,
          itemBuilder: (context, index) {
            final achievements = [
              {'title': 'Đạt 30 giờ tập trung', 'date': '02/05/2025', 'icon': Icons.timer},
              {'title': 'Hoàn thành 10 kế hoạch', 'date': '28/04/2025', 'icon': Icons.check_circle},
              {'title': 'Đạt hiệu suất 85%', 'date': '25/04/2025', 'icon': Icons.trending_up},
            ];
            
            final achievement = achievements[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    achievement['icon'] as IconData,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  achievement['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Đạt được: ${achievement['date']}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context, UserModel user, UserProvider userProvider) {
    final currentUser = userProvider.currentUser;
    final isFriend = currentUser?.friendIds.contains(user.id) ?? false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (isFriend)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Hiển thị dialog xác nhận
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hủy kết bạn'),
                      content: Text('Bạn muốn hủy kết bạn với ${user.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Đồng ý'),
                        ),
                      ],
                    ),
                  ) ?? false;

                  if (confirm) {
                    await userProvider.removeFriend(user.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.person_remove),
                label: const Text('Hủy kết bạn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await userProvider.sendFriendRequest(user.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã gửi lời mời kết bạn đến ${user.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Kết bạn'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 85) {
      return Colors.green;
    } else if (efficiency >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}