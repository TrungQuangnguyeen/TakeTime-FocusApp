import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import
import 'dart:async'; // Add this import for StreamSubscription
import 'package:provider/provider.dart'; // Add this import
import 'providers/user_provider.dart'; // Add this import

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoggedIn = false;
  late final StreamSubscription<AuthState> _authStateSubscription; // Add this

  @override
  void initState() {
    // Add initState
    super.initState();
    _initializeAuthStateListener();
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    // It's good practice to wait for Supabase to be fully initialized
    // if main() involves async operations before Supabase.initialize.
    // However, Supabase.instance.client should be available if initialize completed.
    await Future.delayed(Duration.zero); // Ensures the frame is built
    if (mounted) {
      final session = Supabase.instance.client.auth.currentSession;
      setState(() {
        _isLoggedIn = session != null;
      });
    }
  }

  void _initializeAuthStateListener() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final Session? session = data.session;
          if (mounted) {
            setState(() {
              _isLoggedIn = session != null;
            });
            if (session != null) {
              // Truyền accessToken thuần, không làm sạch, không thêm Bearer
              String accessToken = session.accessToken;
              Provider.of<UserProvider>(
                context,
                listen: false,
              ).setAuthToken(accessToken);
            } else {
              Provider.of<UserProvider>(
                context,
                listen: false,
              ).setAuthToken(null);
            }
          }
        });
  }

  @override
  void dispose() {
    // Add dispose
    _authStateSubscription.cancel();
    super.dispose();
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void setLoggedIn(bool value) {
    // This method might still be used by guest login or other flows.
    // However, for Supabase OAuth, _authStateSubscription will primarily drive _isLoggedIn.
    if (mounted) {
      setState(() {
        _isLoggedIn = value;
      });
      // If manually setting loggedIn to false (e.g. guest logout), ensure token is also cleared.
      // However, Supabase signOut should trigger onAuthStateChange which handles this.
      // if (!value) {
      //   Provider.of<UserProvider>(context, listen: false).setAuthToken(null);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thiết lập thanh trạng thái cho phù hợp với theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _themeMode == ThemeMode.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            _themeMode == ThemeMode.dark
                ? const Color(0xFF1A1A2E)
                : Colors.white,
        systemNavigationBarIconBrightness:
            _themeMode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Smart Time Management',
      debugShowCheckedModeBanner: false, // Loại bỏ banner debug
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E6AF3), // Màu xanh dương hiện đại
          brightness: Brightness.light,
          primary: const Color(0xFF4E6AF3),
          secondary: const Color(0xFF00CFDE),
          tertiary: const Color(0xFFF6C944),
          surface: const Color(0xFFF8F9FA),
          background: const Color(0xFFFCFCFC),
          error: const Color(0xFFE53935),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0xFF000000).withOpacity(0.1),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF4E6AF3),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4E6AF3),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          selectedItemColor: Color(0xFF4E6AF3),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4E6AF3),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF4E6AF3),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4E6AF3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E6AF3),
          brightness: Brightness.dark,
          primary: const Color(0xFF4E6AF3),
          secondary: const Color(0xFF00CFDE),
          tertiary: const Color(0xFFF6C944),
          surface: const Color(0xFF1A1A2E),
          background: const Color(0xFF0F0F1E),
          error: const Color(0xFFE53935),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF4E6AF3),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4E6AF3),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: Color(0xFF4E6AF3),
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4E6AF3),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF4E6AF3),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A40),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4E6AF3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: _themeMode,
      home:
          _isLoggedIn
              ? MainScreen(
                onThemeChanged: toggleTheme,
                onLogout: () async {
                  // Make onLogout async
                  // Signing out from Supabase will trigger onAuthStateChange,
                  // which will then call setAuthToken(null) and set _isLoggedIn = false.
                  // So, direct calls to setLoggedIn(false) or setAuthToken(null) here might be redundant
                  // but can be kept for immediate UI feedback if needed, though onAuthStateChange is the source of truth.
                  await Supabase.instance.client.auth.signOut();
                  // setState(() => _isLoggedIn = false); // This will be handled by onAuthStateChange
                  // Provider.of<UserProvider>(context, listen: false).setAuthToken(null); // Also handled by onAuthStateChange
                },
              )
              : LoginScreen(
                onLogin: () {
                  // For Supabase OAuth, actual login state change is handled by onAuthStateChange.
                  // This onLogin callback might be for other login types or can be removed if not used.
                  // If it's for guest login that doesn't involve Supabase session, it's fine.
                  // For now, we assume Supabase drives the login state.
                  // setState(() => _isLoggedIn = true); // This will be handled by onAuthStateChange
                },
              ),
    );
  }
}
