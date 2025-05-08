import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/focus_session_provider.dart';
import '../../models/focus_session.dart';
import 'focus_timer_screen.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with SingleTickerProviderStateMixin {
  bool _isFocusModeActive = false;
  int _selectedFocusTime = 25; // Mặc định thời gian Pomodoro
  int _customTimeMinutes = 45; // Mặc định thời gian tùy chọn
  late AnimationController _animationController;
  // Removed unused _animation field
  final TextEditingController _customTimeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _customTimeController.text = _customTimeMinutes.toString();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _customTimeController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() async {
    if (!_isFocusModeActive) {
      // Bắt đầu chế độ tập trung - chuyển đến màn hình đếm ngược
      bool? completed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FocusTimerScreen(
            focusTimeMinutes: _selectedFocusTime,
          ),
        ),
      );
      
      // Xử lý kết quả khi trở về từ màn hình tập trung
      if (completed == true) {
        // Phiên tập trung đã hoàn thành
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chúc mừng! Bạn đã hoàn thành phiên tập trung $_selectedFocusTime phút.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Tắt chế độ tập trung (chỉ xảy ra trong màn hình chính)
      setState(() {
        _isFocusModeActive = false;
        _animationController.stop();
        _animationController.reset();
      });
    }
  }

  void _selectFocusTime(int minutes) {
    setState(() {
      _selectedFocusTime = minutes;
    });
  }

  void _showCustomTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chọn thời gian tùy chỉnh',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nhập số phút bạn muốn tập trung:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customTimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số phút',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'phút',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate input
              final inputText = _customTimeController.text.trim();
              if (inputText.isNotEmpty) {
                final minutes = int.tryParse(inputText);
                if (minutes != null && minutes > 0) {
                  setState(() {
                    _customTimeMinutes = minutes;
                    _selectedFocusTime = minutes;
                  });
                }
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6BC0), // Màu tím nhạt
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Đồng ý',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề trang
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'Chế độ Tập trung',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Focus mode cards
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFocusModeCard('Pomodoro', '25 phút', 25),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFocusModeCard('Deep\nWork', '50 phút', 50),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Cập nhật controller với giá trị hiện tại
                              _customTimeController.text = _customTimeMinutes.toString();
                              _showCustomTimeDialog();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedFocusTime == _customTimeMinutes 
                                      ? const Color(0xFF5C6BC0) // Màu xanh tím
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _selectedFocusTime == _customTimeMinutes
                                        ? const Color(0xFF5C6BC0).withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    spreadRadius: _selectedFocusTime == _customTimeMinutes ? 2 : 0,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              child: Column(
                                children: [
                                  Text(
                                    'Tùy chọn',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedFocusTime == _customTimeMinutes
                                          ? const Color(0xFF5C6BC0) 
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_customTimeMinutes phút',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Timer status
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Center(
                      child: Text(
                        _isFocusModeActive ? 'Đang tập trung' : 'Sẵn sàng',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Timer display
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 180,
                        height: 180,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${_selectedFocusTime}:00',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF303F9F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Control buttons
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _toggleFocusMode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0), // Màu tím xanh
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        icon: Icon(
                          _isFocusModeActive 
                              ? Icons.pause 
                              : Icons.play_arrow,
                          size: 24,
                        ),
                        label: Text(
                          _isFocusModeActive ? 'Tạm dừng' : 'Bắt đầu',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // End button
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isFocusModeActive = false;
                            _animationController.stop();
                            _animationController.reset();
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.95),
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.stop, size: 20),
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
                  
                  // Session history section
                  const SizedBox(height: 50),
                  
                  FadeInUp(
                    duration: const Duration(milliseconds: 1100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch sử phiên làm việc',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _showClearHistoryConfirmation();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(
                            'Xóa lịch sử',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Session items
                  Consumer<FocusSessionProvider>(
                    builder: (context, sessionProvider, child) {
                      final sessions = sessionProvider.sessions;
                      
                      if (sessions.isEmpty) {
                        return FadeInUp(
                          duration: const Duration(milliseconds: 1200),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có phiên tập trung nào',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Bắt đầu tập trung để ghi lại lịch sử',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return FadeInUp(
                        duration: const Duration(milliseconds: 1200),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sessions.length > 5 ? 5 : sessions.length,
                            separatorBuilder: (context, index) => 
                                const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return _buildSessionItemFromData(session);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusModeCard(String title, String duration, int minutes) {
    final isSelected = _selectedFocusTime == minutes;
    
    return GestureDetector(
      onTap: () => _selectFocusTime(minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5C6BC0) : Colors.transparent, // Màu xanh tím khi được chọn
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF5C6BC0).withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? const Color(0xFF5C6BC0)
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItemFromData(FocusSession session) {
    final DateFormat dateFormat = DateFormat('HH:mm, d/M');
    final String timeText = dateFormat.format(session.startTime);
    final String durationText = '${session.durationMinutes} phút';
    final bool isCompleted = session.completed;
    
    return Dismissible(
      key: Key(session.id),
      background: Container(
        color: Colors.red.withOpacity(0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Xóa phiên tập trung',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Bạn có chắc muốn xóa phiên tập trung này?',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Hủy',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Xóa',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        Provider.of<FocusSessionProvider>(context, listen: false)
            .deleteSession(session.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa phiên tập trung'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Đóng',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                timeText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                durationText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted 
                        ? Icons.check_circle 
                        : Icons.cancel,
                    size: 16,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCompleted ? 'Hoàn thành' : 'Đã hủy',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa tất cả lịch sử?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tất cả lịch sử phiên tập trung sẽ bị xóa. Bạn có chắc không?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<FocusSessionProvider>(context, listen: false).clearAllSessions();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa tất cả lịch sử'),
                  backgroundColor: Colors.red,
                )
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Xóa tất cả',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}