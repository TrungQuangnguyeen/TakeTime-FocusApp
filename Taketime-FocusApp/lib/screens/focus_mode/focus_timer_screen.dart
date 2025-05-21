import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../widgets/gradient_background.dart';
import '../../providers/focus_session_provider.dart';
import '../../services/focus_mode_service.dart';

class FocusTimerScreen extends StatefulWidget {
  final int focusTimeMinutes;
  final String modeId;
  final FocusModeService focusModeService;

  const FocusTimerScreen({
    super.key,
    required this.focusTimeMinutes,
    required this.modeId,
    required this.focusModeService,
  });

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseAnimation;
  late int _secondsRemaining;
  Timer? _timer;
  bool _isPaused = false;
  bool _soundEnabled = true;
  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.focusTimeMinutes * 60;

    // Animation for breathing effect
    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulseAnimation.repeat(reverse: true);

    // Lưu phiên tập trung mới vào provider
    _startSession();

    // Start the timer
    _startTimer();
  }

  void _startSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Đảm bảo hàm này chỉ được gọi sau khi widget đã được khởi tạo
      final sessionProvider = Provider.of<FocusSessionProvider>(
        context,
        listen: false,
      );
      final session = sessionProvider.startSession(widget.focusTimeMinutes);
      _sessionId = session.id;
    });
  }

  void _playCompletionSound() async {
    if (_soundEnabled) {
      try {
        // Sử dụng HapticFeedback để rung thiết bị khi hoàn thành
        await HapticFeedback.vibrate();
        // Sử dụng SystemSound để phát âm thanh thông báo hệ thống
        await SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        debugPrint('Error playing notification: $e');
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _completeSession(true);
          _playCompletionSound();
          _showCompletionDialog();
        }
      });
    });
  }

  void _pauseResumeTimer() {
    setState(() {
      if (_isPaused) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
      _isPaused = !_isPaused;
    });
  }

  void _completeSession(bool completed) async {
    final sessionProvider = Provider.of<FocusSessionProvider>(
      context,
      listen: false,
    );
    sessionProvider.completeSession(_sessionId, completed);
    // Gọi API cập nhật trạng thái và result
    await widget.focusModeService.updateStatus(widget.modeId, 'Disable');
    await widget.focusModeService.updateResult(
      widget.modeId,
      completed ? 'Completed' : 'Incompleted',
    );
    if (completed) {
      // Thông báo khi hoàn thành đúng thời gian
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bạn đã hoàn thành phiên tập trung!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _cancelFocus() {
    _timer?.cancel();
    _completeSession(false); // Đánh dấu phiên tập trung là đã hủy và gọi API
    Navigator.of(context).pop(false); // Return false to indicate cancelled
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Hoàn thành phiên tập trung!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn đã hoàn thành phiên tập trung ${widget.focusTimeMinutes} phút. Làm tốt lắm!',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pop(true); // Return true to indicate completion
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  children: [
                    // Ẩn nút Back khi timer đang chạy (_timer?.isActive)
                    _timer != null && _timer!.isActive
                        ? const SizedBox(
                          width: 48,
                        ) // Giữ khoảng trống để layout không nhảy
                        : IconButton(
                          onPressed: () {
                            _showExitConfirmationDialog();
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                    Expanded(
                      child: Center(
                        child: FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'Đang tập trung',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Timer display
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 260,
                        height: 260,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(
                                0.3 + (_pulseAnimation.value * 0.1),
                              ),
                              blurRadius: 15 + (_pulseAnimation.value * 10),
                              spreadRadius: 2 + (_pulseAnimation.value * 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _formatTime(_secondsRemaining),
                            style: GoogleFonts.poppins(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(flex: 1),

                // Message
                FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: Text(
                    _isPaused
                        ? 'Tập trung của bạn đang bị tạm dừng'
                        : 'Hãy tập trung vào công việc của bạn',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Control buttons
                // Removed FadeInUp containing ElevatedButton.icon for pause/resume
                // const SizedBox(height: 16), // Removed SizedBox above the End button

                // End button
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _showCancelConfirmationDialog,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.stop, size: 24),
                      label: Text(
                        'Kết thúc',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Kết thúc phiên tập trung?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc muốn kết thúc phiên tập trung này?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Tiếp tục tập trung', style: GoogleFonts.poppins()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelFocus();
                },
                child: Text(
                  'Kết thúc',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // New confirmation dialog for the End button
  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Xác nhận kết thúc',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc muốn kết thúc chế độ tập trung ?\nBạn sẽ mất tiến độ hoàn thành',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Hủy', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _cancelFocus(); // Call the cancel function
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Xác nhận',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }
}
