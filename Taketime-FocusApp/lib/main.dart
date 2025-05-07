import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:developer';
import 'app.dart';
import 'providers/plan_provider.dart';
import 'providers/user_provider.dart';
import 'providers/focus_session_provider.dart'; // Thêm import cho FocusSessionProvider

void main() async {
  // Bắt lỗi toàn cục để tránh crash ứng dụng
  runZonedGuarded(() async {
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
          ChangeNotifierProvider(create: (_) => FocusSessionProvider()), // Thêm FocusSessionProvider
        ],
        child: const MyApp(),
      )
    );
  }, (Object error, StackTrace stack) {
    // Ghi lại lỗi thay vì cho ứng dụng crash
    log('Application error: $error', error: error, stackTrace: stack);
  });
}

