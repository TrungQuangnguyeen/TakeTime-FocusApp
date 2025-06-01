import 'package:flutter/material.dart';
import 'dart:collection';
import '../models/plan_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './user_provider.dart';
import '../services/notification_service.dart';

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
    // Chuẩn hóa ngày được chọn để chỉ lấy phần ngày, tháng, năm
    final normalizedSelectedDate = DateTime(date.year, date.month, date.day);

    final plans =
        _plans
            .where(
              (plan) =>
                  // Chuẩn hóa startTime của plan để chỉ lấy phần ngày, tháng, năm trước khi so sánh
                  DateTime(
                    plan.startTime.year,
                    plan.startTime.month,
                    plan.startTime.day,
                  ) ==
                  normalizedSelectedDate,
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
    _scheduleNotificationsForPlan(plan);
    notifyListeners();
  }

  // Update a plan
  void updatePlan(String id, Plan updatedPlan) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index != -1) {
      _cancelNotificationsForPlan(_plans[index]);
      _plans[index] = updatedPlan;
      _updatePlanStatuses();
      _scheduleNotificationsForPlan(updatedPlan);
      notifyListeners();
    }
  }

  // Delete a plan
  void deletePlan(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index != -1) {
      _cancelNotificationsForPlan(_plans[index]);
      _plans.removeAt(index);
      notifyListeners();
    }
  }

  // Toggle plan completion status
  Future<void> togglePlanCompletion(
    String id,
    UserProvider userProvider,
  ) async {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index != -1) {
      final plan = _plans[index];
      final now = DateTime.now();
      final planDate = DateTime(
        plan.startTime.year,
        plan.startTime.month,
        plan.startTime.day,
      );
      final today = DateTime(now.year, now.month, now.day);

      if (planDate.isBefore(today)) {
        // Nếu kế hoạch đã qua ngày, xóa khỏi database
        await deleteTaskApi(id, userProvider);
      } else {
        // Nếu kế hoạch trong ngày, cập nhật trạng thái hoàn thành
        final updates = {
          'status': !plan.isCompleted ? 'completed' : 'inProgress',
        };
        await updateTask(id, updates, userProvider);
      }
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

        // Schedule notifications only for upcoming or in-progress plans
        for (var plan in _plans) {
          if (plan.status == PlanStatus.upcoming ||
              plan.status == PlanStatus.inProgress) {
            await _scheduleNotificationsForPlan(plan);
          } else {
            // Hủy thông báo cho các kế hoạch đã hoàn thành hoặc quá hạn nếu còn tồn tại
            await _cancelNotificationsForPlan(plan);
          }
        }

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
        // Cancel notifications before fetching again to ensure they are removed
        final planToDelete = _plans.firstWhere((plan) => plan.id == taskId);
        _cancelNotificationsForPlan(planToDelete);
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

  // Helper function to schedule notifications for a given plan
  Future<void> _scheduleNotificationsForPlan(Plan plan) async {
    final notificationService = NotificationService();

    print(
      '[PlanProvider] Attempting to schedule notifications for plan ID: ${plan.id}',
    );

    // Hủy các thông báo cũ trước khi lên lịch mới
    await _cancelNotificationsForPlan(plan);
    print(
      '[PlanProvider] Cancelled existing notifications for plan ID: ${plan.id}',
    );

    // Ensure we only schedule notifications for upcoming or in-progress plans
    if (plan.status == PlanStatus.completed ||
        plan.status == PlanStatus.overdue) {
      print(
        '[PlanProvider] Plan ID ${plan.id} is completed or overdue, not scheduling new notifications.',
      );
      return;
    }

    final startTime = plan.startTime;

    // 1. Thông báo 30 phút trước Timestart
    final thirtyMinBeforeStart = startTime.subtract(
      const Duration(minutes: 30),
    );
    print(
      '[PlanProvider] Plan ID ${plan.id}: Calculated 30min before start time: $thirtyMinBeforeStart',
    );
    // Ensure the scheduled time is in the future
    if (thirtyMinBeforeStart.isAfter(DateTime.now())) {
      final notificationId = notificationService.generateNotificationId(
        plan.id,
        0,
      ); // Type code 0: 30 minutes before start
      print(
        '[PlanProvider] Scheduling 30min before start notification ID: $notificationId at $thirtyMinBeforeStart',
      );
      await notificationService.scheduleNotification(
        id: notificationId,
        title: 'Kế hoạch sắp tới',
        body: 'Kế hoạch \'${plan.title}\' sẽ bắt đầu trong 30 phút.',
        scheduledTime: thirtyMinBeforeStart,
      );
    } else {
      print(
        '[PlanProvider] Plan ID ${plan.id}: 30min before start time is in the past ($thirtyMinBeforeStart), not scheduling.',
      );
    }

    // 2. Thông báo tại Timestart
    final atStartTime = plan.startTime;
    print(
      '[PlanProvider] Plan ID ${plan.id}: Calculated at start time: $atStartTime',
    );
    // Ensure the scheduled time is in the future
    if (atStartTime.isAfter(DateTime.now())) {
      final notificationId = notificationService.generateNotificationId(
        plan.id,
        1,
      ); // Type code 1: At start time
      print(
        '[PlanProvider] Scheduling at start time notification ID: $notificationId at $atStartTime',
      );
      await notificationService.scheduleNotification(
        id: notificationId,
        title: 'Kế hoạch bắt đầu',
        body: 'Kế hoạch \'${plan.title}\' của bạn đã bắt đầu.',
        scheduledTime: atStartTime,
      );
    } else {
      print(
        '[PlanProvider] Plan ID ${plan.id}: At start time is in the past ($atStartTime), not scheduling.',
      );
    }

    // 3. Thông báo 10 phút trước Deadline
    final tenMinBeforeEnd = plan.endTime.subtract(const Duration(minutes: 10));
    print(
      '[PlanProvider] Plan ID ${plan.id}: Calculated 10min before end time: $tenMinBeforeEnd',
    );
    // Ensure the scheduled time is in the future
    if (tenMinBeforeEnd.isAfter(DateTime.now())) {
      final notificationId = notificationService.generateNotificationId(
        plan.id,
        2,
      ); // Type code 2: 10 minutes before end
      print(
        '[PlanProvider] Scheduling 10min before end notification ID: $notificationId at $tenMinBeforeEnd',
      );
      await notificationService.scheduleNotification(
        id: notificationId,
        title: 'Kế hoạch sắp kết thúc',
        body: 'Kế hoạch \'${plan.title}\' còn 10 phút nữa là kết thúc.',
        scheduledTime: tenMinBeforeEnd,
      );
    } else {
      print(
        '[PlanProvider] Plan ID ${plan.id}: 10min before end time is in the past ($tenMinBeforeEnd), not scheduling.',
      );
    }
    print(
      '[PlanProvider] Finished attempting to schedule notifications for plan ID: ${plan.id}',
    );
  }

  // Helper function to cancel all notifications for a given plan
  Future<void> _cancelNotificationsForPlan(Plan plan) async {
    final notificationService = NotificationService();
    print(
      '[PlanProvider] Attempting to cancel notifications for plan ID: ${plan.id}',
    );
    // Cancel all possible notifications for this plan ID
    await notificationService.cancelNotification(
      notificationService.generateNotificationId(plan.id, 0),
    ); // 30min before
    await notificationService.cancelNotification(
      notificationService.generateNotificationId(plan.id, 1),
    ); // At start time
    await notificationService.cancelNotification(
      notificationService.generateNotificationId(plan.id, 2),
    ); // 10min before end
    print(
      '[PlanProvider] Finished cancelling notifications for plan ID: ${plan.id}',
    );
  }

  Future<void> scheduleNotifications(Plan plan) async {
    final notificationService = NotificationService();

    // Hủy các thông báo cũ trước khi lên lịch mới
    await _cancelNotificationsForPlan(plan);

    final startTime = plan.startTime;
    final endTime = plan.endTime;

    // Tạo ID duy nhất cho mỗi thông báo
    final baseId = plan.id.hashCode;

    // Thông báo 30 phút trước khi bắt đầu
    final thirtyMinutesBefore = startTime.subtract(const Duration(minutes: 30));
    if (thirtyMinutesBefore.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: baseId * 100 + 0,
        title: 'Sắp đến giờ bắt đầu kế hoạch',
        body: 'Kế hoạch "${plan.title}" sẽ bắt đầu sau 30 phút',
        scheduledTime: thirtyMinutesBefore,
      );
    }

    // Thông báo khi bắt đầu
    if (startTime.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: baseId * 100 + 1,
        title: 'Đã đến giờ bắt đầu kế hoạch',
        body: 'Kế hoạch "${plan.title}" đã bắt đầu',
        scheduledTime: startTime,
      );
    }

    // Thông báo 10 phút trước khi kết thúc
    final tenMinutesBeforeEnd = endTime.subtract(const Duration(minutes: 10));
    if (tenMinutesBeforeEnd.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: baseId * 100 + 2,
        title: 'Sắp kết thúc kế hoạch',
        body: 'Kế hoạch "${plan.title}" sẽ kết thúc sau 10 phút',
        scheduledTime: tenMinutesBeforeEnd,
      );
    }
  }

  // Method to add a task via POST API
  Future<bool> addTaskApi(Plan plan, UserProvider userProvider) async {
    print('[PlanProvider] addTaskApi called.');

    if (userProvider.currentUser == null) {
      print('[PlanProvider] addTaskApi: User not logged in. Aborting add.');
      return false;
    }

    try {
      final url = Uri.parse('${userProvider.baseUrl}/api/Task');
      print('[PlanProvider] Attempting to add task to URL: $url');
      print('[PlanProvider] Sending headers: ${userProvider.headers}');
      print(
        '[PlanProvider] Sending body: ${jsonEncode(plan.toJson())}',
      ); // Assuming Plan model has toJson

      final response = await http.post(
        url,
        headers: userProvider.headers,
        body: jsonEncode(plan.toJson()),
      );

      print('[PlanProvider] Add Task Status Code: ${response.statusCode}');
      print('[PlanProvider] Add Task Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 200 OK or 201 Created
        print('[PlanProvider] Task added successfully via API.');
        // Sau khi thêm thành công trên backend, fetch lại danh sách task để đảm bảo đồng bộ
        await fetchPlans(userProvider);
        return true;
      } else {
        print(
          '[PlanProvider] Failed to add task: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('[PlanProvider] Error adding task via API (in catch block): $e');
      print('[PlanProvider] StackTrace: $stackTrace');
      return false;
    }
  }

  // TODO: Implement createTask method to send a POST request to the backend API /api/Task
  Future<bool> createTask(Plan plan, UserProvider userProvider) async {
    print('[PlanProvider] createTask called.');

    if (userProvider.currentUser == null ||
        userProvider.currentUser!.projectId == null) {
      print(
        '[PlanProvider] createTask: User not logged in or projectId is null. Aborting task creation.',
      );
      return false;
    }

    // Lấy projectId từ userProvider và gán vào plan object trước khi gửi đi
    // Tính toán reminderTime (10 phút trước deadline)
    final calculatedReminderTime = plan.endTime.subtract(
      const Duration(minutes: 10),
    );

    // Tạo bản sao của plan với projectId, reminderTime đã tính toán và trạng thái mặc định là upcoming
    final planWithFullData = plan.copyWith(
      id: '', // ID sẽ được backend tạo, gửi rỗng hoặc null
      projectId: userProvider.currentUser!.projectId,
      reminderTime: calculatedReminderTime,
      status: PlanStatus.upcoming, // Trạng thái mặc định khi tạo mới
    );

    // Gửi yêu cầu POST đến backend API /api/Task với dữ liệu plan.toJson()
    final url = Uri.parse('${userProvider.baseUrl}/api/Task');
    print('[PlanProvider] Attempting to create task at URL: $url');
    print('[PlanProvider] Sending headers: ${userProvider.headers}');
    // Sử dụng planWithFullData để tạo body, đảm bảo các trường mới được bao gồm
    print(
      '[PlanProvider] Sending body: ${jsonEncode(planWithFullData.toJson())}',
    );

    try {
      final response = await http.post(
        url,
        headers: userProvider.headers,
        body: jsonEncode(planWithFullData.toJson()),
      );

      print('[PlanProvider] Create Task Status Code: ${response.statusCode}');
      print('[PlanProvider] Create Task Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[PlanProvider] Task created successfully via API.');
        // Sau khi tạo thành công trên backend, fetch lại danh sách plans để cập nhật UI và schedule notifications
        await fetchPlans(userProvider);
        return true;
      } else {
        print(
          '[PlanProvider] Failed to create task: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('[PlanProvider] Error creating task via API (in catch block): $e');
      print('[PlanProvider] StackTrace: $stackTrace');
      return false;
    }
  }
}
