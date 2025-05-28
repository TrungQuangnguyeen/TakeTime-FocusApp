import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';

import '../../models/plan_model.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/top_notification.dart'; // Import widget thông báo mới
import 'create_plan_screen.dart';

class PlanDetailScreen extends StatelessWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Format dates and times
    final dateFormatter = DateFormat.yMMMMd();
    final timeFormatter = DateFormat.Hm();
    final dateString = dateFormatter.format(plan.startTime);
    final timeRangeString =
        '${timeFormatter.format(plan.startTime)} - ${timeFormatter.format(plan.endTime)}';

    // Calculate duration
    final duration = plan.endTime.difference(plan.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText =
        '${hours > 0 ? '$hours giờ ' : ''}${minutes > 0 ? '$minutes phút' : ''}';

    void confirmDelete() {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Xóa kế hoạch',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Bạn có chắc chắn muốn xóa kế hoạch này?',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy', style: GoogleFonts.poppins()),
                ),
                TextButton(
                  onPressed: () async {
                    bool success = await Provider.of<PlanProvider>(
                      context,
                      listen: false,
                    ).deleteTaskApi(plan.id, context.read<UserProvider>());

                    if (success) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();

                      TopNotification.show(
                        context,
                        message: 'Đã xóa kế hoạch',
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                      );
                    } else {
                      Navigator.of(context).pop();
                      TopNotification.show(
                        context,
                        message: 'Lỗi khi xóa kế hoạch.',
                        backgroundColor: Colors.red,
                        icon: Icons.error,
                      );
                    }
                  },
                  child: Text(
                    'Xóa',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ],
            ),
      );
    }

    void editPlan() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePlanScreen(initialPlan: plan),
        ),
      ).then((result) {
        // Refresh data khi quay lại từ màn hình chỉnh sửa
        if (result == true) {
          // Nếu có cập nhật, hiển thị thông báo
          TopNotification.show(
            context,
            message: 'Đã cập nhật kế hoạch',
            backgroundColor: Colors.green,
            icon: Icons.check_circle,
          );
        }
      });
    }

    void toggleCompletionStatus() async {
      // Determine the new status
      final newStatus =
          plan.isCompleted ? PlanStatus.inProgress : PlanStatus.completed;

      // Prepare the update data
      final Map<String, dynamic> updates = {
        'status': newStatus.toString().split('.').last,
      };

      // Get UserProvider instance
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Call the API method to update the task status
      bool success = await Provider.of<PlanProvider>(
        context,
        listen: false,
      ).updateTask(plan.id, updates, userProvider);

      if (success) {
        // Show success notification
        TopNotification.show(
          context,
          message:
              newStatus == PlanStatus.completed
                  ? 'Đã đánh dấu hoàn thành'
                  : 'Đã đánh dấu chưa hoàn thành',
          backgroundColor:
              newStatus == PlanStatus.completed ? Colors.green : Colors.orange,
          icon:
              newStatus == PlanStatus.completed
                  ? Icons.check_circle
                  : Icons.replay,
        );
      } else {
        // Show error notification if update failed
        TopNotification.show(
          context,
          message: 'Lỗi khi cập nhật trạng thái kế hoạch.',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: editPlan,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: confirmDelete,
            ),
          ],
          title: Text(
            'Chi tiết kế hoạch',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: plan.getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: plan.getStatusColor().withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        plan.isCompleted
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        color: plan.getStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Trạng thái: ${plan.getStatusText()}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: plan.getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 20,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ]
                            : [
                              Colors.white.withOpacity(0.7),
                              Colors.white.withOpacity(0.4),
                            ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ]
                            : [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                            ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tiêu đề',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Time and date
              Row(
                children: [
                  // Date
                  Expanded(
                    child: FadeInLeft(
                      duration: const Duration(milliseconds: 600),
                      child: _buildInfoCard(
                        context,
                        title: 'Ngày',
                        content: dateString,
                        icon: Icons.calendar_today,
                        iconColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Duration
                  Expanded(
                    child: FadeInRight(
                      duration: const Duration(milliseconds: 600),
                      child: _buildInfoCard(
                        context,
                        title: 'Thời lượng',
                        content: durationText,
                        icon: Icons.hourglass_bottom,
                        iconColor: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Time range
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: _buildInfoCard(
                  context,
                  title: 'Thời gian',
                  content: timeRangeString,
                  icon: Icons.access_time,
                  iconColor: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              // Priority
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: _buildInfoCard(
                  context,
                  title: 'Mức độ ưu tiên',
                  content: _getPriorityText(plan.priority),
                  icon: plan.getPriorityIcon(),
                  iconColor: plan.getPriorityColor(),
                ),
              ),

              // Notes
              if (plan.note.isNotEmpty) ...[
                const SizedBox(height: 20),
                FadeInDown(
                  duration: const Duration(milliseconds: 900),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height:
                        plan.note.length > 100
                            ? 200.0
                            : 150.0, // Fixed height with explicit double values
                    borderRadius: 20,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isDark
                              ? [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ]
                              : [
                                Colors.white.withOpacity(0.7),
                                Colors.white.withOpacity(0.4),
                              ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isDark
                              ? [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ]
                              : [
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.2),
                              ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ghi chú',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan.note,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Action Button
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          plan.isCompleted ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: toggleCompletionStatus,
                    icon: Icon(
                      plan.isCompleted ? Icons.replay : Icons.check_circle,
                    ),
                    label: Text(
                      plan.isCompleted
                          ? 'Đánh dấu chưa hoàn thành'
                          : 'Đánh dấu hoàn thành',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriorityText(PlanPriority priority) {
    switch (priority) {
      case PlanPriority.low:
        return 'Thấp';
      case PlanPriority.medium:
        return 'Trung bình';
      case PlanPriority.high:
        return 'Cao';
    }
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 85,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDark
                ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
                : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.4),
                ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDark
                ? [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ]
                : [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.2),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(icon, size: 20, color: iconColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
