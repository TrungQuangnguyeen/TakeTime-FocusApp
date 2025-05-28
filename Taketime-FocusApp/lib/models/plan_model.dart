import 'package:flutter/material.dart';

enum PlanPriority { low, medium, high }

enum PlanStatus { upcoming, inProgress, completed, overdue }

enum CalendarFormat { week, month, twoWeeks }

class Plan {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String note;
  final PlanPriority priority;
  final bool isCompleted;
  final PlanStatus status;
  final String? projectId;
  final DateTime? reminderTime;

  const Plan({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.note = '',
    this.priority = PlanPriority.medium,
    this.isCompleted = false,
    required this.status,
    this.projectId,
    this.reminderTime,
  });

  // Lấy icon tương ứng với mức độ ưu tiên
  IconData getPriorityIcon() {
    switch (priority) {
      case PlanPriority.low:
        return Icons.low_priority;
      case PlanPriority.medium:
        return Icons.flag;
      case PlanPriority.high:
        return Icons.priority_high;
    }
  }

  // Lấy màu tương ứng với mức độ ưu tiên
  Color getPriorityColor() {
    switch (priority) {
      case PlanPriority.low:
        return Colors.green;
      case PlanPriority.medium:
        return Colors.orange;
      case PlanPriority.high:
        return Colors.red;
    }
  }

  // Lấy màu tương ứng với trạng thái
  Color getStatusColor() {
    switch (status) {
      case PlanStatus.upcoming:
        return Colors.blue;
      case PlanStatus.inProgress:
        return Colors.amber;
      case PlanStatus.completed:
        return Colors.green;
      case PlanStatus.overdue:
        return Colors.red;
    }
  }

  // Lấy chuỗi văn bản mô tả trạng thái
  String getStatusText() {
    switch (status) {
      case PlanStatus.upcoming:
        return 'Sắp tới';
      case PlanStatus.inProgress:
        return 'Đang diễn ra';
      case PlanStatus.completed:
        return 'Hoàn thành';
      case PlanStatus.overdue:
        return 'Quá hạn';
    }
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Plan copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? note,
    PlanPriority? priority,
    bool? isCompleted,
    PlanStatus? status,
    String? projectId,
    DateTime? reminderTime,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  @override
  String toString() {
    return 'Plan{id: $id, title: $title, startTime: $startTime, endTime: $endTime, note: $note, priority: $priority, isCompleted: $isCompleted, status: $status, projectId: $projectId, reminderTime: $reminderTime}';
  }

  // Factory constructor để tạo đối tượng Plan từ JSON
  factory Plan.fromJson(Map<String, dynamic> json) {
    // Hàm helper để safely get a value and cast it
    T? safeGet<T>(Map<String, dynamic> json, String key) {
      if (json.containsKey(key) && json[key] != null && json[key] is T) {
        return json[key] as T;
      }
      return null;
    }

    // Hàm helper để parse DateTime hoặc trả về null nếu giá trị null/invalid
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        // DateTime.parse có thể xử lý chuỗi ISO 8601 bao gồm cả múi giờ
        return DateTime.parse(
          value as String,
        ).toLocal(); // <<< Chuyển sang múi giờ local để hiển thị
      } catch (e) {
        print(
          'Error parsing DateTime: $value, Error: $e',
        ); // Log lỗi parse DateTime
        return null;
      }
    }

    // Hàm helper để parse priority string sang enum PlanPriority
    PlanPriority parsePriority(dynamic value) {
      if (value == null) return PlanPriority.medium; // Mặc định là medium
      final lowerCaseValue = (value as String).toLowerCase();
      switch (lowerCaseValue) {
        case 'low':
          return PlanPriority.low;
        case 'mid': // Backend trả về 'mid'
          return PlanPriority.medium;
        case 'high':
          return PlanPriority.high;
        default:
          print(
            'Unknown priority value: $value',
          ); // Log giá trị priority không mong muốn
          return PlanPriority.medium; // Mặc định là medium
      }
    }

    // Hàm helper để parse status string sang enum PlanStatus
    PlanStatus parseStatus(dynamic value) {
      if (value == null) return PlanStatus.upcoming; // Mặc định là upcoming
      final lowerCaseValue = (value as String).toLowerCase();
      switch (lowerCaseValue) {
        case 'upcoming':
          return PlanStatus.upcoming;
        case 'inprogress': // Giả định backend gửi 'inprogress'
          return PlanStatus.inProgress;
        case 'completed':
          return PlanStatus.completed;
        case 'overdue':
          return PlanStatus.overdue;
        default:
          print(
            'Unknown status value: $value',
          ); // Log giá trị status không mong muốn
          return PlanStatus.upcoming; // Mặc định là upcoming
      }
    }

    // Sử dụng safeGet và parseDateTime cho các trường thời gian
    final startTime = parseDateTime(json['timestart'] ?? json['startTime']);
    final endTime = parseDateTime(json['deadline'] ?? json['endTime']);
    final reminderTime = parseDateTime(
      json['reminder_time'] ?? json['reminderTime'],
    );

    return Plan(
      id:
          safeGet<String>(json, 'task_id') ??
          safeGet<String>(json, 'id') ??
          '', // Backend sử dụng 'task_id' hoặc 'id'
      title: safeGet<String>(json, 'title') ?? '', // Đảm bảo non-null
      startTime: startTime ?? DateTime.now(), // Sử dụng biến đã parse
      endTime:
          endTime ??
          DateTime.now().add(const Duration(hours: 1)), // Sử dụng biến đã parse
      note:
          safeGet<String>(json, 'description') ??
          safeGet<String>(json, 'note') ??
          '', // Backend sử dụng 'description' hoặc 'note'
      priority: parsePriority(json['priority']),
      isCompleted:
          safeGet<bool>(json, 'is_completed') ??
          false, // Giả định có trường is_completed
      status: parseStatus(json['status']), // Sử dụng hàm parseStatus
      projectId:
          safeGet<String>(json, 'project_id') ??
          safeGet<String>(json, 'projectId'), // Parse projectId
      reminderTime: reminderTime, // Sử dụng biến đã parse
    );
  }

  // Thêm phương thức toJson để chuyển đổi Plan object thành JSON
  Map<String, dynamic> toJson() {
    return {
      //'id': id, // ID thường do backend tạo khi thêm mới
      'title': title,
      'description': note, // Sử dụng 'description' cho note
      'timestart':
          startTime.toIso8601String(), // Sử dụng 'timestart' cho startTime
      'deadline': endTime.toIso8601String(), // Sử dụng 'deadline' cho endTime
      'priority':
          priority
              .toString()
              .split('.')
              .last
              .toLowerCase(), // Chuyển đổi enum sang String lowercase
      'status':
          status
              .toString()
              .split('.')
              .last
              .toLowerCase(), // Thêm status vào toJson
      'project_id': projectId, // Thêm projectId vào toJson
      'reminder_time':
          reminderTime
              ?.toIso8601String(), // Thêm reminderTime vào toJson (có thể null)
    };
  }
}
