import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home/home_screen.dart';
import 'blocked_apps/blocked_app_screen.dart';
import 'plan/plan_screen.dart'; // Đổi import từ time_management thành plan
import 'plan/create_plan_screen.dart'; // Thêm import cho CreatePlanScreen
import 'focus_mode/focus_mode_screen.dart';
import 'profile/profile_screen.dart';
import 'friend/friend_screen.dart'; // Thêm import cho màn hình kết bạn
import '../services/auth_service.dart'; // Import AuthService

class MainScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final VoidCallback onLogout;

  const MainScreen({super.key, required this.onThemeChanged, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  final AuthService _authService = AuthService(); // Add this line

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _fabAnimationController.forward();
    _updateScreens();
  }

  void _updateScreens() {
    _screens.clear();
    _screens.addAll([
      const HomeScreen(),
      const PlanScreen(), // Đặt PlanScreen lên trước
      const BlockedAppScreen(), // Chuyển BlockedAppScreen xuống sau
      const FocusModeScreen(),
      const FriendScreen(),
      // Pass the AuthService instance to ProfileScreen
      ProfileScreen(authService: _authService, onThemeChanged: widget.onThemeChanged), 
    ]);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: const Color(0xFF1A1A2E),
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Colors.white,
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
        floatingActionButton: _selectedIndex == 1
            ? ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton(
                  onPressed: () {
                    // Mở trực tiếp trang CreatePlanScreen khi nhấn vào nút + ở tab kế hoạch
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreatePlanScreen(),
                      ),
                    );
                  },
                  elevation: 4,
                  backgroundColor: primaryColor,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: primaryColor,
              unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              showUnselectedLabels: true,
              elevation: 0,
              items: [
                _buildNavItem(
                  label: 'Trang chủ',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  index: 0,
                ),
                _buildNavItem(
                  label: 'Kế hoạch',
                  icon: Icons.event_note_outlined,
                  activeIcon: Icons.event_note,
                  index: 1,
                ),
                _buildNavItem(
                  label: 'Giới hạn',
                  icon: Icons.block_outlined,
                  activeIcon: Icons.block_rounded,
                  index: 2,
                ),
                _buildNavItem(
                  label: 'Tập trung',
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book,
                  index: 3,
                ),
                _buildNavItem(
                  label: 'Kết bạn',
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  index: 4,
                ),
                _buildNavItem(
                  label: 'Hồ sơ',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  index: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return BottomNavigationBarItem(
      icon: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isSelected ? 20 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Icon(isSelected ? activeIcon : icon),
        ],
      ),
      label: label,
    );
  }
}