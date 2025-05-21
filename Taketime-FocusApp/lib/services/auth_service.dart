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
      print('AuthService: User not authenticated, cannot fetch profile.');
      return null;
    }

    try {
      print(
        'AuthService: Fetching profile directly from user object for user ${user.id}',
      );
      Map<String, dynamic> userProfileData = {};

      // 1. Lấy email trực tiếp từ đối tượng user
      if (user.email != null) {
        userProfileData['email'] = user.email;
      } else {
        print('AuthService: Authenticated user has no email in user.email.');
      }

      // 2. Lấy thông tin từ user.userMetadata
      // userMetadata chứa dữ liệu như tên, ảnh đại diện từ OAuth provider (Facebook, Google, etc.)
      // Các key trong userMetadata có thể khác nhau tùy theo provider.
      // Ví dụ:
      // - Facebook: 'name', 'picture' (có thể là một Map picture.data.url)
      // - Google: 'name', 'full_name', 'avatar_url', 'picture'

      final metadata = user.userMetadata;
      print('AuthService: User metadata: $metadata');

      if (metadata != null) {
        // Lấy tên người dùng
        if (metadata.containsKey('name')) {
          userProfileData['full_name'] = metadata['name'];
        } else if (metadata.containsKey('full_name')) {
          userProfileData['full_name'] = metadata['full_name'];
        }
        // Thử lấy 'preferred_username' nếu có, thường dùng cho tên đăng nhập
        if (metadata.containsKey('preferred_username')) {
          userProfileData['username'] = metadata['preferred_username'];
        }

        // Lấy URL ảnh đại diện
        if (metadata.containsKey('avatar_url')) {
          userProfileData['avatar_url'] = metadata['avatar_url'];
        } else if (metadata.containsKey('picture')) {
          dynamic pictureData = metadata['picture'];
          if (pictureData is String) {
            userProfileData['avatar_url'] = pictureData;
          } else if (pictureData is Map &&
              pictureData.containsKey('data') &&
              pictureData['data'] is Map &&
              pictureData['data'].containsKey('url')) {
            // Cấu trúc ảnh đại diện của Facebook: { "data": { "url": "..." } }
            userProfileData['avatar_url'] = pictureData['data']['url'];
          }
        }
      }

      // Nếu không có tên đầy đủ, thử sử dụng phần đầu của email làm tên mặc định
      if (userProfileData['full_name'] == null && user.email != null) {
        userProfileData['full_name'] = user.email!.split('@').first;
      }

      if (userProfileData.isEmpty) {
        print(
          'AuthService: No profile data could be extracted from user object.',
        );
        // Trả về email làm fallback nếu có
        if (user.email != null)
          return {
            'email': user.email,
            'full_name': user.email!.split('@').first,
          };
        return null;
      }

      print(
        'AuthService: Returning profile data from user object: $userProfileData',
      );
      return userProfileData;
    } catch (e) {
      print('AuthService: Error fetching user profile from user object: $e');
      // Fallback: trả về ít nhất email nếu có, nếu không thì null
      final currentUserEmail = _supabase.auth.currentUser?.email;
      if (currentUserEmail != null) {
        return {
          'email': currentUserEmail,
          'full_name': currentUserEmail.split('@').first,
        };
      }
      return null;
    }
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
        redirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
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

  // Thêm hàm này để lấy access token Supabase
  Future<String?> getAccessToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return token; // Trả về token gốc, không làm sạch
  }
}
