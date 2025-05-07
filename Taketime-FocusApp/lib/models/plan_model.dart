import 'package:flutter/material.dart';

enum PlanPriority {
  low,
  medium,
  high,
}

enum PlanStatus {
  upcoming,
  inProgress,
  completed,
  overdue,
}

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
    if (isCompleted) {
      return Colors.green;
    }
    
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
    if (isCompleted) {
      return 'Hoàn thành';
    }
    
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
}