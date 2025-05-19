import 'package:flutter/material.dart';
import 'dart:collection';
import '../models/plan_model.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './user_provider.dart';

class PlanProvider with ChangeNotifier {
  final List<Plan> _plans = [];

  // Sample data for testing (will be removed in production)
  PlanProvider() {
    // _addSamplePlans();
  }

  // Get plans sorted by date
  UnmodifiableListView<Plan> get plans {
    _updatePlanStatuses();
    return UnmodifiableListView(_plans);
  }

  // Get plans for a specific date
  List<Plan> getPlansForDate(DateTime date) {
    _updatePlanStatuses();
    final plans =
        _plans
            .where(
              (plan) =>
                  plan.startTime.year == date.year &&
                  plan.startTime.month == date.month &&
                  plan.startTime.day == date.day,
            )
            .toList();

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
        status:
            !plan.isCompleted ? PlanStatus.completed : PlanStatus.inProgress,
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
      if (plan.endTime.isBefore(now) && plan.status != PlanStatus.completed) {
        _plans[i] = plan.copyWith(status: PlanStatus.overdue);
      } else if (plan.startTime.isBefore(now) &&
          plan.endTime.isAfter(now) &&
          plan.status == PlanStatus.upcoming) {
        _plans[i] = plan.copyWith(status: PlanStatus.inProgress);
      }
    }
  }

  // Add sample plans for testing
  void _addSamplePlans() {
    final now = DateTime.now();

    // Today's plans
    addPlan(
      Plan(
        id: '1',
        title: 'Họp nhóm dự án',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 30),
        note: 'Thảo luận về tiến độ và kế hoạch tiếp theo',
        priority: PlanPriority.high,
      ),
    );

    addPlan(
      Plan(
        id: '2',
        title: 'Gửi báo cáo hằng tuần',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 0),
        note: 'Tổng hợp công việc đã hoàn thành trong tuần',
        priority: PlanPriority.medium,
      ),
    );

    // Tomorrow's plans
    final tomorrow = now.add(const Duration(days: 1));
    addPlan(
      Plan(
        id: '3',
        title: 'Học Flutter',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
        note: 'Học về state management và Provider',
        priority: PlanPriority.medium,
      ),
    );

    // Day after tomorrow
    final dayAfterTomorrow = now.add(const Duration(days: 2));
    addPlan(
      Plan(
        id: '4',
        title: 'Xem lại tiến độ dự án',
        startTime: DateTime(
          dayAfterTomorrow.year,
          dayAfterTomorrow.month,
          dayAfterTomorrow.day,
          13,
          0,
        ),
        endTime: DateTime(
          dayAfterTomorrow.year,
          dayAfterTomorrow.month,
          dayAfterTomorrow.day,
          14,
          30,
        ),
        note: 'Chuẩn bị bản trình bày và demo',
        priority: PlanPriority.high,
      ),
    );

    // Next week
    final nextWeek = now.add(const Duration(days: 7));
    addPlan(
      Plan(
        id: '5',
        title: 'Nghỉ ngơi',
        startTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10, 0),
        endTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 18, 0),
        note: 'Đi chơi với gia đình',
        priority: PlanPriority.low,
      ),
    );

    // Completed plan
    addPlan(
      Plan(
        id: '6',
        title: 'Hoàn thành thiết kế UI',
        startTime: DateTime(now.year, now.month, now.day - 1, 9, 0),
        endTime: DateTime(now.year, now.month, now.day - 1, 12, 0),
        note: 'Thiết kế UI cho ứng dụng quản lý thời gian',
        priority: PlanPriority.high,
        isCompleted: true,
        status: PlanStatus.completed,
      ),
    );
  }

  // Hàm fetch danh sách Task từ backend (nhận UserProvider instance)
  Future<void> fetchPlans(UserProvider userProvider) async {
    print('[PlanProvider] fetchPlans called.');

    if (userProvider.currentUser == null) {
      print('[PlanProvider] fetchPlans: User not logged in. Aborting fetch.');
      _plans.clear(); // Xóa danh sách cũ nếu người dùng không đăng nhập
      notifyListeners();
      return;
    }

    // Có thể thêm loading state nếu cần
    // _isLoading = true; notifyListeners();

    try {
      final url = Uri.parse('${userProvider.baseUrl}/api/Task/my');
      print('[PlanProvider] Attempting to fetch tasks from URL: $url');

      final response = await http.get(url, headers: userProvider.headers);

      print('[PlanProvider] Fetch Tasks Status Code: ${response.statusCode}');
      print('[PlanProvider] Fetch Tasks Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Plan> fetchedPlans =
            data.map((json) => Plan.fromJson(json)).toList();

        _plans.clear(); // Xóa dữ liệu mẫu hoặc dữ liệu cũ
        _plans.addAll(fetchedPlans); // Thêm dữ liệu mới từ API

        print('[PlanProvider] Successfully fetched ${_plans.length} tasks.');

        // Cập nhật trạng thái local sau khi fetch
        _updatePlanStatuses();

        notifyListeners();
      } else {
        print(
          '[PlanProvider] Failed to fetch tasks: ${response.statusCode} ${response.body}',
        );
        // Có thể xóa danh sách cũ hoặc giữ lại tùy chiến lược
        // _plans.clear();
      }
    } catch (e, stackTrace) {
      print('[PlanProvider] Error fetching plans (overall try-catch): $e');
      print('[PlanProvider] StackTrace: $stackTrace');
      // Có thể xóa danh sách cũ hoặc giữ lại tùy chiến lược
      // _plans.clear();
    } finally {
      // Nếu có loading state
      // _isLoading = false; notifyListeners();
    }
  }

  // Method to update a task via PATCH API
  Future<bool> updateTask(
    String taskId,
    Map<String, dynamic> updates,
    UserProvider userProvider,
  ) async {
    print('[PlanProvider] updateTask called for Task ID: $taskId');

    if (userProvider.currentUser == null) {
      print('[PlanProvider] updateTask: User not logged in. Aborting update.');
      return false;
    }

    try {
      final url = Uri.parse('${userProvider.baseUrl}/api/Task/$taskId');
      print('[PlanProvider] Attempting to update task at URL: $url');
      print('[PlanProvider] Sending headers: ${userProvider.headers}');
      print('[PlanProvider] Sending body: ${jsonEncode(updates)}');

      final response = await http.patch(
        url,
        headers: userProvider.headers,
        body: jsonEncode(updates),
      );

      print('[PlanProvider] Update Task Status Code: ${response.statusCode}');
      print('[PlanProvider] Update Task Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 OK or 204 No Content
        print('[PlanProvider] Task updated successfully via API.');
        // Sau khi cập nhật thành công trên backend, fetch lại danh sách task để đảm bảo đồng bộ
        await fetchPlans(userProvider);
        return true;
      } else {
        print(
          '[PlanProvider] Failed to update task: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('[PlanProvider] Error updating task via API (in catch block): $e');
      print('[PlanProvider] StackTrace: $stackTrace');
      return false;
    }
  }

  // Method to delete a task via DELETE API
  Future<bool> deleteTaskApi(String taskId, UserProvider userProvider) async {
    print('[PlanProvider] deleteTaskApi called for Task ID: $taskId');

    if (userProvider.currentUser == null) {
      print(
        '[PlanProvider] deleteTaskApi: User not logged in. Aborting deletion.',
      );
      return false;
    }

    try {
      final url = Uri.parse('${userProvider.baseUrl}/api/Task/$taskId');
      print('[PlanProvider] Attempting to delete task at URL: $url');
      print('[PlanProvider] Sending headers: ${userProvider.headers}');

      final response = await http.delete(url, headers: userProvider.headers);

      print('[PlanProvider] Delete Task Status Code: ${response.statusCode}');
      print('[PlanProvider] Delete Task Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 OK or 204 No Content
        print('[PlanProvider] Task deleted successfully via API.');
        // Sau khi xóa thành công trên backend, fetch lại danh sách task để đảm bảo đồng bộ
        await fetchPlans(userProvider);
        return true;
      } else {
        print(
          '[PlanProvider] Failed to delete task: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('[PlanProvider] Error deleting task via API (in catch block): $e');
      print('[PlanProvider] StackTrace: $stackTrace');
      return false;
    }
  }
}
