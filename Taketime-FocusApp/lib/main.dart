import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:developer';
import 'app.dart';
import 'providers/plan_provider.dart';
import 'providers/user_provider.dart';
import 'providers/focus_session_provider.dart'; // Thêm import cho FocusSessionProvider
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // Import NotificationService

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://zedemxhbxmhuouatxpmq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplZGVteGhieG1odW91YXR4cG1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzMTY1NzksImV4cCI6MjA2MDg5MjU3OX0.qxTTlSP5fwu4GcRC29Y_ZroCAthUx2X_F6dOHG0M9_E',
  );

  // Khởi tạo Notification Service
  await NotificationService().init();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await initializeDateFormatting('vi_VN', null);

      // Đảm bảo lỗi Flutter được ghi nhận
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        log('Flutter error: ${details.exception}', error: details);
      };

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlanProvider()),
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(
              create: (_) => FocusSessionProvider(),
            ), // Thêm FocusSessionProvider
          ],
          child: const AppInitializer(
            child: MyApp(),
          ), // Sử dụng widget khởi tạo
        ),
      );
    },
    (Object error, StackTrace stack) {
      // Ghi lại lỗi thay vì cho ứng dụng crash
      log('Application error: $error', error: error, stackTrace: stack);
    },
  );
}

// Widget khởi tạo access token
class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({required this.child, super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  //xử lý auth
  Future<void> _initAuth() async {
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();
    if (accessToken != null && mounted) {
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).setAuthToken(accessToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
