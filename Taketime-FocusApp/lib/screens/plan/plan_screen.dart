import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' as table_calendar;
import 'package:animate_do/animate_do.dart';
import '../../models/plan_model.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/gradient_background.dart';
import 'create_plan_screen.dart';
import 'plan_detail_screen.dart';
import '../../providers/user_provider.dart';
import 'dart:async';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  table_calendar.CalendarFormat _calendarFormat =
      table_calendar.CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _tabController = TabController(length: 4, vsync: this);

    // Thiết lập timer cập nhật trạng thái mỗi 30 giây
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      planProvider
          .notifyListeners(); // Kích hoạt getter plans để cập nhật trạng thái
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      print('[PlanScreen] User logged in, fetching plans...');
      planProvider.fetchPlans(userProvider);
    } else {
      if (planProvider.plans.isNotEmpty) {
        print('[PlanScreen] User not logged in, clearing plans.');
        planProvider.plans.clear();
        planProvider.notifyListeners();
      }
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
            'Kế Hoạch',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _calendarFormat == table_calendar.CalendarFormat.month
                    ? Icons.calendar_view_week
                    : Icons.calendar_view_month,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _calendarFormat =
                      _calendarFormat == table_calendar.CalendarFormat.month
                          ? table_calendar.CalendarFormat.week
                          : table_calendar.CalendarFormat.month;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Calendar
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _buildCalendar(isDark, theme),
            ),

            const SizedBox(height: 8),

            // Selected Date Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      _selectedDay == null
                          ? 'Hôm nay'
                          : DateFormat(
                            'EEEE, dd/MM/yyyy',
                            'vi_VN',
                          ).format(_selectedDay!),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Plans List
            Expanded(
              child: Consumer<PlanProvider>(
                builder: (context, planProvider, child) {
                  if (_selectedDay == null) return const SizedBox();

                  final selectedPlans = planProvider.getPlansForDate(
                    _selectedDay!,
                  );

                  if (selectedPlans.isEmpty) {
                    return FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 70,
                              color: isDark ? Colors.white30 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có kế hoạch nào',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToCreatePlan(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(
                                'Tạo kế hoạch mới',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: selectedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = selectedPlans[index];
                        final delay = 800 + (index * 100);

                        return FadeInUp(
                          duration: Duration(milliseconds: delay),
                          child: _buildPlanCard(context, plan, isDark),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Điều hướng trực tiếp đến trang CreatePlanScreen mà không có tham số
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
            );
          },
          backgroundColor: Colors.deepPurpleAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDark, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 4,
      color:
          isDark
              ? Colors.grey.shade900.withOpacity(0.7)
              : Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: table_calendar.TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: (day) {
          final provider = Provider.of<PlanProvider>(context, listen: false);
          return provider.getPlansForDate(day);
        },
        selectedDayPredicate: (day) {
          return table_calendar.isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: table_calendar.CalendarStyle(
          markersAlignment: Alignment.bottomCenter,
          markerDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: GoogleFonts.poppins(
            color: Colors.red.withOpacity(0.7),
          ),
          outsideTextStyle: GoogleFonts.poppins(color: Colors.grey),
          defaultTextStyle: GoogleFonts.poppins(),
        ),
        headerStyle: table_calendar.HeaderStyle(
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: isDark ? Colors.white : Colors.black87,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        calendarBuilders: table_calendar.CalendarBuilders(
          dowBuilder: (context, day) {
            final locale = Localizations.localeOf(context).languageCode;
            final dowText = DateFormat.E(locale).format(day);
            return Center(
              child: Text(
                dowText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      day.weekday == DateTime.sunday ||
                              day.weekday == DateTime.saturday
                          ? Colors.red.withOpacity(0.7)
                          : isDark
                          ? Colors.white70
                          : Colors.black87,
                ),
              ),
            );
          },
          // Thêm markerBuilder tùy chỉnh để chỉ hiển thị 1 chấm cho mỗi ngày có kế hoạch
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 1,
                child: Container(
                  height: 6.0,
                  width: 6.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan, bool isDark) {
    final startTime = DateFormat.Hm().format(plan.startTime);
    final endTime = DateFormat.Hm().format(plan.endTime);
    final priorityColor = plan.getPriorityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color:
          isDark
              ? Colors.grey.shade900.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlanDetailScreen(plan: plan),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                              decoration:
                                  plan.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: plan.getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan.getStatusText(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: plan.getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Time and priority
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$startTime - $endTime',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          plan.getPriorityIcon(),
                          size: 16,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plan.priority == PlanPriority.low
                              ? 'Thấp'
                              : plan.priority == PlanPriority.medium
                              ? 'Trung bình'
                              : 'Cao',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreatePlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
    );
    if (result == true) {
      // Sau khi thêm kế hoạch mới, cập nhật lại danh sách
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        await planProvider.fetchPlans(userProvider);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }
}
