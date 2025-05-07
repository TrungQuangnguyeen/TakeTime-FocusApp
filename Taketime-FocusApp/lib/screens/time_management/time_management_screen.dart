import 'package:flutter/material.dart';
import '../../widgets/bar_chart_item.dart';

class TimeManagementScreen extends StatelessWidget {
  const TimeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thống kê thời gian sử dụng',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Bar chart section
                Container(
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
                  child: Column(
                    children: [
                      BarChartItem(
                        appName: 'Facebook',
                        usage: 3.5,
                        maxUsage: 5.0,
                        color: Colors.blue,
                      ),
                      BarChartItem(
                        appName: 'YouTube',
                        usage: 2.0,
                        maxUsage: 5.0,
                        color: Colors.red,
                      ),
                      BarChartItem(
                        appName: 'Instagram',
                        usage: 1.5,
                        maxUsage: 5.0,
                        color: Colors.pink,
                      ),
                      BarChartItem(
                        appName: 'TikTok',
                        usage: 1.0,
                        maxUsage: 5.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Summary section
                Text(
                  'Tóm tắt',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                  child: Column(
                    children: [
                      _buildSummaryItem(
                        context,
                        'Tổng thời gian sử dụng',
                        '8 giờ 30 phút',
                        Icons.timer,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildSummaryItem(
                        context,
                        'Ứng dụng sử dụng nhiều nhất',
                        'Facebook',
                        Icons.facebook,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildSummaryItem(
                        context,
                        'Thời gian tập trung',
                        '2 giờ',
                        Icons.self_improvement,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}