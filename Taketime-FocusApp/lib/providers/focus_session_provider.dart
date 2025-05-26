import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session.dart';
import 'package:audioplayers/audioplayers.dart';

class FocusSessionProvider with ChangeNotifier {
  List<FocusSession> _sessions = [];
  final String _storageKey = 'focus_sessions';
  final Uuid _uuid = const Uuid();

  List<FocusSession> get sessions => [..._sessions];

  FocusSessionProvider() {
    _loadSessions();
  }

  // Tải các phiên tập trung từ SharedPreferences
  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionsString = prefs.getString(_storageKey);

      if (sessionsString == null) return;

      final List<dynamic> decodedData = jsonDecode(sessionsString);
      _sessions =
          decodedData
              .map(
                (item) => FocusSession.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList();

      // Sắp xếp theo thời gian bắt đầu, mới nhất lên đầu
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading focus sessions: $e');
    }
  }

  // Lưu tất cả phiên tập trung vào SharedPreferences
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> sessionsMap =
          _sessions.map((session) => session.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(sessionsMap));
    } catch (e) {
      debugPrint('Error saving focus sessions: $e');
    }
  }

  // Bắt đầu một phiên tập trung mới
  FocusSession startSession(int durationMinutes) {
    final newSession = FocusSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
      completed: false,
    );

    _sessions.insert(0, newSession); // Thêm vào đầu danh sách
    _saveSessions();
    notifyListeners();

    return newSession;
  }

  // Cập nhật kết quả của phiên tập trung
  Future<void> completeSession(String sessionId, bool completed) async {
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index != -1) {
      final session = _sessions[index];
      final updatedSession = FocusSession(
        id: session.id,
        startTime: session.startTime,
        endTime: DateTime.now(),
        durationMinutes: session.durationMinutes,
        completed: completed,
      );

      _sessions[index] = updatedSession;
      await _saveSessions();
      notifyListeners();

      // Play completion sound if session is completed successfully
      if (completed) {
        try {
          final player = AudioPlayer();
          await player.play(
            AssetSource('sounds/completion_sound.mp3'),
          ); // Replace with your sound file name
        } catch (e) {
          debugPrint('Error playing completion sound: $e');
        }
      }
    }
  }

  // Xóa một phiên tập trung
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((session) => session.id == sessionId);
    await _saveSessions();
    notifyListeners();
  }

  // Xóa tất cả phiên tập trung
  Future<void> clearAllSessions() async {
    _sessions.clear();
    await _saveSessions();
    notifyListeners();
  }

  // Lấy các phiên tập trung theo ngày
  List<FocusSession> getSessionsByDate(DateTime date) {
    return _sessions.where((session) {
      final sessionDate = session.startTime;
      return sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day;
    }).toList();
  }

  // Lấy tổng thời gian tập trung trong ngày
  int getTotalFocusMinutesForDate(DateTime date) {
    final sessionsForDate = getSessionsByDate(date);
    return sessionsForDate
        .where((session) => session.completed) // Chỉ tính các phiên hoàn thành
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }
}
