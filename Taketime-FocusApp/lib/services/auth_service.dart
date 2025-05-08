import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For checking platform

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getter for the current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
        // For non-web, you might need to configure a redirect URL.
        // For web, Supabase handles it automatically if the URL is in your Supabase dashboard.
      );
    } on AuthException catch (e) {
      print('Supabase Google Sign-In Error: ${e.message}');
      // Handle error, e.g., show a snackbar
      rethrow;
    } catch (e) {
      print('Unexpected Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        // redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
        // Similar to Google, configure redirect for non-web if needed.
      );
    } on AuthException catch (e) {
      print('Supabase Facebook Sign-In Error: ${e.message}');
      // Handle error
      rethrow;
    } catch (e) {
      print('Unexpected Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      print('Supabase Sign-Out Error: ${e.message}');
      // Handle error
      rethrow;
    } catch (e) {
      print('Unexpected Sign-Out Error: $e');
      rethrow;
    }
  }

  Future<void> signInAsGuest() async {
    try {
      await _supabase.auth.signInAnonymously();
      print("Signed in anonymously with Supabase");
    } on AuthException catch (e) {
      print('Supabase Anonymous Sign-In Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Anonymous Sign-In Error: $e');
      rethrow;
    }
  }
}
