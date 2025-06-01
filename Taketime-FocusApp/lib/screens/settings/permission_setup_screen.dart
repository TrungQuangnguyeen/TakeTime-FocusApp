import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_blocking_service.dart';
import '../debug/accessibility_debug_screen.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  Map<String, bool> _permissions = {
    'accessibility': false,
    'usageStats': false,
    'overlay': false,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final permissions = await AppBlockingService.checkAllPermissions();
      setState(() {
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _permissions.values.every((granted) => granted);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Cài Đặt Quyền',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _checkPermissions,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
            tooltip: 'Kiểm tra lại',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: allGranted 
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        allGranted ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        allGranted 
                          ? 'Tất Cả Quyền Đã Được Cấp!'
                          : 'Cần Cấp Quyền Để Sử Dụng',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        allGranted
                          ? 'Ứng dụng sẵn sàng chặn các ứng dụng khác'
                          : 'Vui lòng cấp quyền theo hướng dẫn bên dưới',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Permissions list
                Text(
                  'Danh Sách Quyền Cần Thiết',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Usage Stats Permission
                _buildPermissionCard(
                  title: 'Usage Stats Permission',
                  description: 'Theo dõi thời gian sử dụng ứng dụng',
                  icon: Icons.bar_chart,
                  isGranted: _permissions['usageStats'] ?? false,
                  onRequestPermission: () async {
                    await AppBlockingService.requestUsageStatsPermission();
                    _showInstructionDialog(
                      'Usage Stats Permission',
                      'Tìm "TakeTime" trong danh sách và bật toggle bên cạnh.\n\nĐường dẫn: Settings → Apps → Special access → Usage access',
                    );
                  },
                  onOpenSettings: () => AppBlockingService.openGeneralSettings(),
                ),
                
                const SizedBox(height: 12),
                
                // Overlay Permission  
                _buildPermissionCard(
                  title: 'Display Over Other Apps',
                  description: 'Hiển thị cảnh báo khi chặn ứng dụng',
                  icon: Icons.layers,
                  isGranted: _permissions['overlay'] ?? false,
                  onRequestPermission: () async {
                    await AppBlockingService.requestOverlayPermission();
                    _showInstructionDialog(
                      'Display Over Other Apps',
                      'Tìm "TakeTime" và bật "Allow display over other apps".\n\nĐường dẫn: Settings → Apps → Special access → Display over other apps',
                    );
                  },
                  onOpenSettings: () => AppBlockingService.openAppSettings(),
                ),
                
                const SizedBox(height: 12),
                
                // Accessibility Permission
                _buildPermissionCard(
                  title: 'Accessibility Service',
                  description: 'Chặn ứng dụng thực sự khi vượt giới hạn',
                  icon: Icons.accessibility,
                  isGranted: _permissions['accessibility'] ?? false,
                  onRequestPermission: () async {
                    await AppBlockingService.requestAccessibilityPermission();
                    _showInstructionDialog(
                      'Accessibility Service',
                      'Tìm "TakeTime" hoặc "App Blocking Service", nhấn vào và bật "Use service".\n\nĐường dẫn: Settings → Accessibility → Downloaded apps → TakeTime',
                    );
                  },
                  onOpenSettings: () => AppBlockingService.openGeneralSettings(),
                ),
                
                const SizedBox(height: 32),
                
                // Quick actions
                if (!allGranted) ...[
                  Text(
                    'Hành Động Nhanh',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => AppBlockingService.openAppSettings(),
                          icon: const Icon(Icons.settings_applications),
                          label: Text(
                            'App Settings',
                            style: GoogleFonts.poppins(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => AppBlockingService.openGeneralSettings(),
                          icon: const Icon(Icons.settings),
                          label: Text(
                            'General Settings',
                            style: GoogleFonts.poppins(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _requestAllPermissions,
                      icon: const Icon(Icons.security),
                      label: Text(
                        'Cấp Tất Cả Quyền',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                  if (allGranted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: Text(
                        'Hoàn Tất',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Debug button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccessibilityDebugScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: Text(
                      'Debug Accessibility Service',
                      style: GoogleFonts.poppins(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequestPermission,
    required VoidCallback onOpenSettings,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGranted 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isGranted ? Icons.check_circle : Icons.warning,
                color: isGranted ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          
          if (!isGranted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRequestPermission,
                    child: Text(
                      'Cấp Quyền',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: onOpenSettings,
                    child: Text(
                      'Mở Settings',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    final List<Future<void>> requests = [];
    
    if (!(_permissions['usageStats'] ?? false)) {
      requests.add(AppBlockingService.requestUsageStatsPermission());
    }
    if (!(_permissions['overlay'] ?? false)) {
      requests.add(AppBlockingService.requestOverlayPermission());
    }
    if (!(_permissions['accessibility'] ?? false)) {
      requests.add(AppBlockingService.requestAccessibilityPermission());
    }
    
    if (requests.isNotEmpty) {
      await Future.wait(requests);
      
      _showInstructionDialog(
        'Cấp Tất Cả Quyền',
        'Các trang settings đã được mở. Vui lòng:\n\n'
        '1. Bật Usage Stats cho TakeTime\n'
        '2. Bật Display over other apps cho TakeTime\n'
        '3. Bật Accessibility Service cho TakeTime\n\n'
        'Sau khi cấp xong, quay lại và nhấn nút làm mới.',
      );
    }
  }

  void _showInstructionDialog(String title, String instructions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          instructions,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đã hiểu',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPermissions();
            },
            child: Text(
              'Kiểm tra lại',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}
