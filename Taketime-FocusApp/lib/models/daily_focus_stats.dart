class DailyFocusStats {
  final int totalSessions;
  final int completedSessions;
  final int totalCompletedDurationMinutes;

  DailyFocusStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalCompletedDurationMinutes,
  });

  factory DailyFocusStats.fromJson(Map<String, dynamic> json) {
    return DailyFocusStats(
      totalSessions: json['totalSessions'] as int,
      completedSessions: json['completedSessions'] as int,
      totalCompletedDurationMinutes:
          json['totalCompletedDurationMinutes'] as int,
    );
  }
}
