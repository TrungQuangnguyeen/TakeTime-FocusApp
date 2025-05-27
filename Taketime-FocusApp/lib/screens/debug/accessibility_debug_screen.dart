import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_blocking_service.dart';

class AccessibilityDebugScreen extends StatefulWidget {
  const AccessibilityDebugScreen({super.key});

  @override
  State<AccessibilityDebugScreen> createState() => _AccessibilityDebugScreenState();
}

class _AccessibilityDebugScreenState extends State<AccessibilityDebugScreen> {
  Map<String, bool> _permissions = {};
  String _debugInfo = "Đang kiểm tra...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsWithDebug();
  }
  Future<void> _checkPermissionsWithDebug() async {
    setState(() => _isLoading = true);
    
    try {
      // Check permissions
      final permissions = await AppBlockingService.checkAllPermissions();
      
      // Get detailed debug info
      final debugData = await AppBlockingService.getAccessibilityDebugInfo();
      
      // Build debug info string
      String debugInfo = "=== DEBUG ACCESSIBILITY SERVICE ===\n";
      debugInfo += "Package: ${debugData['packageName'] ?? 'Unknown'}\n";
      debugInfo += "Service: ${debugData['serviceName'] ?? 'Unknown'}\n";
      debugInfo += "Enabled Services: ${debugData['enabledServices'] ?? 'null'}\n\n";
      
      debugInfo += "CHECK RESULTS:\n";
      debugInfo += "- Direct Check: ${debugData['directCheck'] ?? false}\n";
      debugInfo += "- Simple Check: ${debugData['simpleCheck'] ?? false}\n";
      debugInfo += "- Package Check: ${debugData['packageCheck'] ?? false}\n";
      debugInfo += "- AccessibilityManager Check: ${debugData['accessibilityManagerCheck'] ?? false}\n";
      debugInfo += "- Final Result: ${debugData['isEnabled'] ?? false}\n\n";
      
      debugInfo += "RUNNING SERVICES:\n";
      debugInfo += "- Count: ${debugData['runningServicesCount'] ?? 0}\n";
      if (debugData['runningServiceIds'] != null) {
        final serviceIds = debugData['runningServiceIds'] as List;
        for (int i = 0; i < serviceIds.length; i++) {
          debugInfo += "- Service $i: ${serviceIds[i]}\n";
        }
      }
      
      if (debugData['error'] != null) {
        debugInfo += "\nERROR: ${debugData['error']}\n";
      }
      
      if (debugData['accessibilityManagerError'] != null) {
        debugInfo += "\nACCESSIBILITY MANAGER ERROR: ${debugData['accessibilityManagerError']}\n";
      }
      
      debugInfo += "\nFLUTTER PERMISSION RESULTS:\n";
      debugInfo += "- Accessibility: ${permissions['accessibility']}\n";
      debugInfo += "- Usage Stats: ${permissions['usageStats']}\n";
      debugInfo += "- Overlay: ${permissions['overlay']}\n\n";
      
      // Analyze the situation
      if (!permissions['accessibility']!) {
        debugInfo += "❌ ACCESSIBILITY SERVICE KHÔNG ĐƯỢC NHẬN DIỆN!\n\n";
        
        if (debugData['enabledServices'] == null || debugData['enabledServices'] == 'null') {
          debugInfo += "NGUYÊN NHÂN: Không có accessibility service nào được bật\n";
          debugInfo += "GIẢI PHÁP: Vào Settings → Accessibility và bật service\n";
        } else if (!(debugData['directCheck'] ?? false) && !(debugData['simpleCheck'] ?? false)) {
          debugInfo += "NGUYÊN NHÂN: Service có thể đã được bật nhưng với tên khác\n";
          debugInfo += "GIẢI PHÁP: \n";
          debugInfo += "1. Tắt service trong Settings → Accessibility\n";
          debugInfo += "2. Bật lại service\n";
          debugInfo += "3. Restart ứng dụng TakeTime\n";
        } else {
          debugInfo += "NGUYÊN NHÂN: Service detected nhưng Flutter không nhận ra\n";
          debugInfo += "GIẢI PHÁP: Restart ứng dụng hoặc reboot thiết bị\n";
        }
      } else {
        debugInfo += "✅ ACCESSIBILITY SERVICE HOẠT ĐỘNG TỐT!\n";
      }
      
      setState(() {
        _permissions = permissions;
        _debugInfo = debugInfo;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _debugInfo = "Lỗi: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Accessibility',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _checkPermissionsWithDebug,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
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
                // Status cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'Accessibility',
                        _permissions['accessibility'] ?? false,
                        Icons.accessibility,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard(
                        'Usage Stats',
                        _permissions['usageStats'] ?? false,
                        Icons.bar_chart,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard(
                        'Overlay',
                        _permissions['overlay'] ?? false,
                        Icons.layers,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Debug info
                Text(
                  'Thông Tin Debug',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _debugInfo,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Text(
                  'Hành Động',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AppBlockingService.requestAccessibilityPermission();
                      _showInstructionDialog();
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(
                      'Mở Accessibility Settings',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => AppBlockingService.openAppSettings(),
                    icon: const Icon(Icons.apps),
                    label: Text(
                      'Mở App Settings',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Manual instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng Dẫn Chi Tiết',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Mở Settings → Accessibility\\n'
                        '2. Tìm "Downloaded apps" hoặc "Downloaded services"\\n'
                        '3. Tìm "TakeTime" hoặc "App Blocking Service"\\n'
                        '4. Nhấn vào và bật "Use service"\\n'
                        '5. Nhấn "OK" khi có dialog xác nhận\\n'
                        '6. Quay lại ứng dụng và nhấn Refresh',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[700],
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

  Widget _buildStatusCard(String title, bool isEnabled, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isEnabled ? Colors.green[700] : Colors.red[700],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isEnabled ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hướng Dẫn Cấp Quyền',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trong trang Accessibility Settings:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Tìm phần "Downloaded apps" hoặc "Downloaded services"\\n'
              '2. Tìm "TakeTime" hoặc "App Blocking Service"\\n'
              '3. Nhấn vào tên service\\n'
              '4. Bật toggle "Use service"\\n'
              '5. Nhấn "OK" để xác nhận',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Lưu ý: Sau khi bật service, hãy quay lại ứng dụng và nhấn nút Refresh để kiểm tra lại.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
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
              _checkPermissionsWithDebug();
            },
            child: Text(
              'Refresh',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}
