import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For checking platform

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getter for the current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final metadata = user.userMetadata;
      if (metadata != null) {
        return metadata.cast<String, dynamic>();
      } else if (user.email != null) {
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
        // For non-web, you might need to configure a redirect URL.
        // For web, Supabase handles it automatically if the URL is in your Supabase dashboard.
      );
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
        // Similar to Google, configure redirect for non-web if needed.
      );
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInAsGuest() async {
    try {
      await _supabase.auth.signInAnonymously();
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Thêm hàm này để lấy access token Supabase
  Future<String?> getAccessToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return token; // Trả về token gốc, không làm sạch
  }
}
