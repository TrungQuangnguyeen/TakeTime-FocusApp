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

  const Plan({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.note = '',
    this.priority = PlanPriority.medium,
    this.isCompleted = false,
    this.status = PlanStatus.upcoming,
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
    final now = DateTime.now();

    // Ưu tiên hiển thị 'Completed' nếu status từ backend là completed
    if (status == PlanStatus.completed) {
      return Colors.green;
    }

    // Kiểm tra trạng thái dựa trên thời gian thực nếu chưa hoàn thành
    if (endTime.isBefore(now)) {
      return Colors.red; // Overdue
    } else if (startTime.isBefore(now) || startTime.isAtSameMomentAs(now)) {
      // Nếu timestart đã đến hoặc đang diễn ra và chưa quá hạn
      return Colors.amber; // InProgress
    } else {
      // If startTime is in the future
      return Colors.blue; // Upcoming
    }
    // Fallback to status from backend if needed (shouldn't be reached with above logic)
    // switch (status) {
    //   case PlanStatus.upcoming:
    //     return Colors.blue;
    //   case PlanStatus.inProgress:
    //     return Colors.amber;
    //   case PlanStatus.completed:
    //     return Colors.green;
    //   case PlanStatus.overdue:
    //     return Colors.red;
    // }
  }

  // Lấy chuỗi văn bản mô tả trạng thái
  String getStatusText() {
    final now = DateTime.now();

    // Ưu tiên hiển thị 'Hoàn thành' nếu status từ backend là completed
    if (status == PlanStatus.completed) {
      return 'Hoàn thành';
    }

    // Kiểm tra trạng thái dựa trên thời gian thực nếu chưa hoàn thành
    if (endTime.isBefore(now)) {
      return 'Quá hạn'; // Overdue
    } else if (startTime.isBefore(now) || startTime.isAtSameMomentAs(now)) {
      // Nếu timestart đã đến hoặc đang diễn ra và chưa quá hạn
      return 'Đang diễn ra'; // InProgress
    } else {
      // If startTime is in the future
      return 'Sắp tới'; // Upcoming
    }
    // Fallback to status from backend if needed (shouldn't be reached with above logic)
    // switch (status) {
    //   case PlanStatus.upcoming:
    //     return 'Sắp tới';
    //   case PlanStatus.inProgress:
    //     return 'Đang diễn ra';
    //   case PlanStatus.completed:
    //     return 'Hoàn thành';
    //   case PlanStatus.overdue:
    //     return 'Quá hạn';
    // }
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
    );
  }

  @override
  String toString() {
    return 'Plan{id: $id, title: $title, startTime: $startTime, endTime: $endTime, note: $note, priority: $priority, isCompleted: $isCompleted, status: $status}';
  }

  // Factory constructor để tạo đối tượng Plan từ JSON
  factory Plan.fromJson(Map<String, dynamic> json) {
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

    return Plan(
      id: json['task_id'] as String, // Backend sử dụng 'task_id'
      title: json['title'] as String? ?? '', // Đảm bảo non-null
      startTime:
          parseDateTime(json['timestart']) ??
          DateTime.now(), // Sử dụng parseDateTime
      endTime:
          parseDateTime(json['deadline']) ??
          DateTime.now().add(const Duration(hours: 1)), // Sử dụng parseDateTime
      note:
          json['description'] as String? ??
          '', // Backend sử dụng 'description', đảm bảo non-null
      priority: parsePriority(json['priority']), // Sử dụng parsePriority
      isCompleted:
          json['is_completed'] as bool? ??
          false, // Giả định có trường is_completed (hoặc logic tính toán)
      status: parseStatus(json['status']), // Sử dụng hàm parseStatus
    );
  }
}
