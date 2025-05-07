import 'package:flutter/material.dart';
import 'dart:collection';
import '../models/plan_model.dart';

class PlanProvider with ChangeNotifier {
  final List<Plan> _plans = [];
  
  // Sample data for testing (will be removed in production)
  PlanProvider() {
    _addSamplePlans();
  }

  // Get plans sorted by date
  UnmodifiableListView<Plan> get plans {
    _updatePlanStatuses();
    return UnmodifiableListView(_plans);
  }

  // Get plans for a specific date
  List<Plan> getPlansForDate(DateTime date) {
    _updatePlanStatuses();
    final plans = _plans.where((plan) =>
      plan.startTime.year == date.year &&
      plan.startTime.month == date.month &&
      plan.startTime.day == date.day
    ).toList();
    
    // Sắp xếp theo mức độ ưu tiên từ cao xuống thấp (high -> medium -> low)
    plans.sort((a, b) {
      // Ưu tiên đầu tiên: High > Medium > Low
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      
      // Nếu cùng mức ưu tiên thì sắp xếp theo thời gian bắt đầu
      return a.startTime.compareTo(b.startTime);
    });
    
    return plans;
  }

  // Get plans for a specific week
  List<Plan> getPlansForWeek(DateTime startOfWeek) {
    _updatePlanStatuses();
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return _plans.where((plan) {
      final planDate = DateTime(
        plan.startTime.year,
        plan.startTime.month,
        plan.startTime.day,
      );
      
      return planDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             planDate.isBefore(endOfWeek);
    }).toList();
  }

  // Add a new plan
  void addPlan(Plan plan) {
    _plans.add(plan);
    _updatePlanStatuses();
    notifyListeners();
  }

  // Update a plan
  void updatePlan(String id, Plan updatedPlan) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index != -1) {
      _plans[index] = updatedPlan;
      _updatePlanStatuses();
      notifyListeners();
    }
  }

  // Delete a plan
  void deletePlan(String id) {
    _plans.removeWhere((plan) => plan.id == id);
    notifyListeners();
  }

  // Toggle plan completion status
  void togglePlanCompletion(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index != -1) {
      final plan = _plans[index];
      _plans[index] = plan.copyWith(
        isCompleted: !plan.isCompleted,
        status: !plan.isCompleted ? PlanStatus.completed : PlanStatus.inProgress,
      );
      notifyListeners();
    }
  }

  // Update plan statuses based on current time
  void _updatePlanStatuses() {
    final now = DateTime.now();
    
    for (int i = 0; i < _plans.length; i++) {
      final plan = _plans[i];
      
      // Skip completed plans
      if (plan.isCompleted) {
        continue;
      }
      
      // Check if plan is overdue
      if (plan.endTime.isBefore(now)) {
        _plans[i] = plan.copyWith(status: PlanStatus.overdue);
      } else if (plan.startTime.isBefore(now) && plan.endTime.isAfter(now)) {
        _plans[i] = plan.copyWith(status: PlanStatus.inProgress);
      }
    }
  }

  // Add sample plans for testing
  void _addSamplePlans() {
    final now = DateTime.now();
    
    // Today's plans
    addPlan(Plan(
      id: '1',
      title: 'Họp nhóm dự án',
      startTime: DateTime(now.year, now.month, now.day, 9, 0),
      endTime: DateTime(now.year, now.month, now.day, 10, 30),
      note: 'Thảo luận về tiến độ và kế hoạch tiếp theo',
      priority: PlanPriority.high,
    ));
    
    addPlan(Plan(
      id: '2',
      title: 'Gửi báo cáo hằng tuần',
      startTime: DateTime(now.year, now.month, now.day, 14, 0),
      endTime: DateTime(now.year, now.month, now.day, 15, 0),
      note: 'Tổng hợp công việc đã hoàn thành trong tuần',
      priority: PlanPriority.medium,
    ));
    
    // Tomorrow's plans
    final tomorrow = now.add(const Duration(days: 1));
    addPlan(Plan(
      id: '3',
      title: 'Học Flutter',
      startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0),
      endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
      note: 'Học về state management và Provider',
      priority: PlanPriority.medium,
    ));
    
    // Day after tomorrow
    final dayAfterTomorrow = now.add(const Duration(days: 2));
    addPlan(Plan(
      id: '4',
      title: 'Xem lại tiến độ dự án',
      startTime: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 13, 0),
      endTime: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 14, 30),
      note: 'Chuẩn bị bản trình bày và demo',
      priority: PlanPriority.high,
    ));
    
    // Next week
    final nextWeek = now.add(const Duration(days: 7));
    addPlan(Plan(
      id: '5',
      title: 'Nghỉ ngơi',
      startTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10, 0),
      endTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 18, 0),
      note: 'Đi chơi với gia đình',
      priority: PlanPriority.low,
    ));
    
    // Completed plan
    addPlan(Plan(
      id: '6',
      title: 'Hoàn thành thiết kế UI',
      startTime: DateTime(now.year, now.month, now.day - 1, 9, 0),
      endTime: DateTime(now.year, now.month, now.day - 1, 12, 0),
      note: 'Thiết kế UI cho ứng dụng quản lý thời gian',
      priority: PlanPriority.high,
      isCompleted: true,
      status: PlanStatus.completed,
    ));
  }
}