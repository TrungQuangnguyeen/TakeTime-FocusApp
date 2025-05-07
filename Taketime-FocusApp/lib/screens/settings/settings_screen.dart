import 'package:flutter/material.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_category.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cài đặt',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SettingsCategory(
                  title: 'Tài khoản',
                  children: [
                    SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Thông tin cá nhân',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: onLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsCategory(
                  title: 'Giao diện',
                  children: [
                    SettingsTile(
                      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      title: 'Chế độ tối',
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (_) => onThemeChanged(),
                      ),
                      onTap: onThemeChanged,
                    ),
                  ],
                ),
                // Add more settings categories here
              ],
            ),
          ),
        ),
      ),
    );
  }
}