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
    required this.status,
    this.projectId,
    this.reminderTime,
  });

  bool get isCompleted => status == PlanStatus.completed;

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

  Plan copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? note,
    PlanPriority? priority,
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
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  @override
  String toString() {
    return 'Plan{id: $id, title: $title, startTime: $startTime, endTime: $endTime, note: $note, priority: $priority, status: $status, projectId: $projectId, reminderTime: $reminderTime}';
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    T? safeGet<T>(Map<String, dynamic> json, String key) {
      if (json.containsKey(key) && json[key] != null && json[key] is T) {
        return json[key] as T;
      }
      return null;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        // DateTime.parse có thể xử lý chuỗi ISO 8601 bao gồm cả múi giờ
        return DateTime.parse(value as String).toLocal();
      } catch (e) {
        print('Error parsing DateTime: $value, Error: $e');
        return null;
      }
    }

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
          print('Unknown priority value: $value');
          return PlanPriority.medium;
      }
    }

    PlanStatus parseStatus(dynamic value) {
      if (value == null) return PlanStatus.upcoming;
      final lowerCaseValue = (value as String).toLowerCase();
      switch (lowerCaseValue) {
        case 'upcoming':
          return PlanStatus.upcoming;
        case 'inprogress':
          return PlanStatus.inProgress;
        case 'completed':
          return PlanStatus.completed;
        case 'overdue':
          return PlanStatus.overdue;
        default:
          print('Unknown status value: $value');
          return PlanStatus.upcoming;
      }
    }

    final startTime = parseDateTime(json['timestart'] ?? json['startTime']);
    final endTime = parseDateTime(json['deadline'] ?? json['endTime']);
    final reminderTime = parseDateTime(
      json['reminder_time'] ?? json['reminderTime'],
    );

    return Plan(
      id: safeGet<String>(json, 'task_id') ?? safeGet<String>(json, 'id') ?? '',
      title: safeGet<String>(json, 'title') ?? '', // Đảm bảo non-null
      startTime: startTime ?? DateTime.now(),
      endTime:
          endTime ??
          DateTime.now().add(const Duration(hours: 1)), // Sử dụng biến đã parse
      note:
          safeGet<String>(json, 'description') ??
          safeGet<String>(json, 'note') ??
          '',
      priority: parsePriority(json['priority']),
      status: parseStatus(json['status']),
      projectId:
          safeGet<String>(json, 'project_id') ??
          safeGet<String>(json, 'projectId'),
      reminderTime: reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': note,
      'timestart': startTime.toIso8601String(),
      'deadline': endTime.toIso8601String(),
      'priority':
          priority == PlanPriority.medium
              ? 'mid'
              : priority.toString().split('.').last.toLowerCase(),
      'status': status.toString().split('.').last.toLowerCase(),
      'project_id': projectId,
      'reminder_time': reminderTime?.toIso8601String(),
    };
  }
}
