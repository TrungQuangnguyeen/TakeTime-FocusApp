import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/plan_model.dart';
import '../../providers/plan_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/top_notification.dart'; // Import widget thông báo mới

class CreatePlanScreen extends StatefulWidget {
  final Plan? initialPlan; // Nếu có, sử dụng để chỉnh sửa thay vì tạo mới

  const CreatePlanScreen({super.key, this.initialPlan});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;
  PlanPriority _priority = PlanPriority.medium;

  bool get _isEditing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();

    // Khởi tạo thời gian mặc định hoặc lấy từ kế hoạch đang chỉnh sửa
    if (_isEditing) {
      _titleController.text = widget.initialPlan!.title;
      _noteController.text = widget.initialPlan!.note;
      _startTime = widget.initialPlan!.startTime;
      _endTime = widget.initialPlan!.endTime;
      _priority = widget.initialPlan!.priority;
    } else {
      // Mặc định: Bắt đầu từ giờ hiện tại, kéo dài 1 giờ
      final now = DateTime.now();
      _startTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        (now.minute ~/ 15) * 15, // Làm tròn đến 15 phút gần nhất
      );
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      final planProvider = Provider.of<PlanProvider>(
        context,
        listen: false,
      ); // Get PlanProvider instance

      if (currentUser == null) {
        // Show error if user is not logged in
        TopNotification.show(
          context,
          message: 'Lỗi: Không tìm thấy thông tin người dùng.',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
        return;
      }

      // Nếu đang chỉnh sửa task
      if (_isEditing) {
        print('[CreatePlanScreen] Updating existing task...');

        // Chuẩn bị dữ liệu cập nhật
        final Map<String, dynamic> updates = {
          'title': _titleController.text.trim(),
          'description': _noteController.text.trim(),
          'timestart': _startTime.toIso8601String(),
          'deadline': _endTime.toIso8601String(),
          // Tính toán reminder_time (10 phút trước deadline)
          'reminder_time':
              _endTime.subtract(const Duration(minutes: 10)).toIso8601String(),
          'priority':
              _priority == PlanPriority.medium
                  ? 'mid'
                  : _priority.toString().split('.').last.toLowerCase(),
          // Status có thể được cập nhật riêng nếu cần, ở đây không thay đổi status khi chỉnh sửa thời gian/nội dung
          // 'status': ...
        };

        // Gọi phương thức cập nhật trong PlanProvider
        bool success = await planProvider.updateTask(
          widget.initialPlan!.id,
          updates,
          userProvider,
        );

        if (success) {
          TopNotification.show(
            context,
            message: 'Đã cập nhật kế hoạch thành công.',
            backgroundColor: Colors.green,
            icon: Icons.check_circle,
          );
          Navigator.of(
            context,
          ).pop(true); // Trả về true để báo hiệu cập nhật thành công
        } else {
          TopNotification.show(
            context,
            message: 'Lỗi khi cập nhật kế hoạch.',
            backgroundColor: Colors.red,
            icon: Icons.error,
          );
        }
        return; // Kết thúc hàm sau khi xử lý cập nhật
      }

      // Nếu đang tạo task mới, sử dụng createTask
      print('[CreatePlanScreen] Creating new task using createTask...');

      final newTask = Plan(
        // Không cần tạo ID tạm thời ở đây nữa, backend sẽ tạo
        id: '', // Gửi rỗng hoặc null, tùy backend yêu cầu
        title: _titleController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        note: _noteController.text.trim(),
        priority: _priority,
        status: PlanStatus.upcoming,
        // project_id, reminderTime, status, isCompleted sẽ được xử lý bởi createTask và backend
      );

      // Gọi phương thức createTask trong PlanProvider
      // Thay thế addTaskApi bằng createTask
      bool success = await planProvider.createTask(newTask, userProvider);

      if (success) {
        TopNotification.show(
          context,
          message: 'Đã tạo kế hoạch mới thành công!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        Navigator.pop(context); // Đóng màn hình sau khi tạo thành công
      } else {
        // Lỗi đã được xử lý và hiển thị trong createTask
        print('[CreatePlanScreen] Failed to create task via createTask.');
        // Thông báo lỗi đã hiển thị từ createTask, không cần hiển thị lại ở đây
      }

      // TODO: Consider adding a finally block here to hide loading indicator
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Đảm bảo rằng thời gian kết thúc luôn sau thời gian bắt đầu
        if (_endTime.isBefore(_startTime) ||
            _endTime.isAtSameMomentAs(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );

    if (pickedTime != null) {
      final newEndTime = DateTime(
        _endTime.year,
        _endTime.month,
        _endTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Kiểm tra nếu thời gian kết thúc là sau thời gian bắt đầu
      if (newEndTime.isAfter(_startTime)) {
        // Kiểm tra thời lượng tối thiểu (15 phút)
        final duration = newEndTime.difference(_startTime).inMinutes;
        if (duration < 15) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kế hoạch phải kéo dài ít nhất 15 phút',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _endTime = newEndTime;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thời gian kết thúc phải sau thời gian bắt đầu',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Kiểm tra nếu ngày đã chọn là trong quá khứ
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      if (selectedDate.isBefore(today)) {
        // Hiển thị xác nhận cho ngày trong quá khứ
        final confirmPast = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Xác nhận ngày trong quá khứ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Bạn đang tạo kế hoạch cho ngày trong quá khứ. Bạn có chắc chắn muốn tiếp tục?',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Hủy', style: GoogleFonts.poppins()),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Xác nhận', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
        );

        if (confirmPast != true) {
          return;
        }
      }

      setState(() {
        _startTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        _endTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _isEditing ? 'Chỉnh sửa kế hoạch' : 'Tạo kế hoạch mới',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: _buildSectionTitle('Tiêu đề', Icons.title),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildGlassmorphicContainer(
                    child: TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu đề kế hoạch',
                        hintStyle: GoogleFonts.poppins(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Date picker
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildSectionTitle('Ngày', Icons.calendar_today),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: _buildGlassmorphicContainer(
                    onTap: _selectDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat.yMMMMd().format(_startTime),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.calendar_month,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Time range
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: _buildSectionTitle('Thời gian', Icons.access_time),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 900),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassmorphicContainer(
                          onTap: _selectStartTime,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bắt đầu',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                  ),
                                ),
                                Text(
                                  DateFormat.Hm().format(_startTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGlassmorphicContainer(
                          onTap: _selectEndTime,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kết thúc',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                  ),
                                ),
                                Text(
                                  DateFormat.Hm().format(_endTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Priority
                FadeInDown(
                  duration: const Duration(milliseconds: 1000),
                  child: _buildSectionTitle('Mức độ ưu tiên', Icons.flag),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 1100),
                  child: _buildGlassmorphicContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPriorityButton(
                            PlanPriority.low,
                            'Thấp',
                            Colors.green,
                          ),
                          _buildPriorityButton(
                            PlanPriority.medium,
                            'Trung bình',
                            Colors.orange,
                          ),
                          _buildPriorityButton(
                            PlanPriority.high,
                            'Cao',
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Note
                FadeInDown(
                  duration: const Duration(milliseconds: 1200),
                  child: _buildSectionTitle('Ghi chú', Icons.note),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 1300),
                  child: _buildGlassmorphicContainer(
                    height: 120,
                    child: TextFormField(
                      controller: _noteController,
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập ghi chú (không bắt buộc)',
                        hintStyle: GoogleFonts.poppins(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 5,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Save button
                FadeInUp(
                  duration: const Duration(milliseconds: 1400),
                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _savePlan,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _isEditing ? 'Cập nhật' : 'Lưu kế hoạch',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicContainer({
    required Widget child,
    double? height,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: height ?? 60,
        borderRadius: 15,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
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
        child: child,
      ),
    );
  }

  Widget _buildPriorityButton(
    PlanPriority priority,
    String label,
    Color color,
  ) {
    final isSelected = _priority == priority;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = priority;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                priority == PlanPriority.low
                    ? Icons.low_priority
                    : priority == PlanPriority.medium
                    ? Icons.flag
                    : Icons.priority_high,
                color:
                    isSelected
                        ? color
                        : theme.iconTheme.color?.withOpacity(0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? color : theme.textTheme.bodyLarge?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
