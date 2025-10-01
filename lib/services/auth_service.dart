import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Get current user session
  Session? get currentSession => _client.auth.currentSession;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Handle AuthException and provide user-friendly messages
  String _handleAuthError(AuthException e) {
    switch (e.statusCode) {
      case '400':
        return 'Invalid email/phone or password. Please check your credentials and try again.';
      case '401':
        return 'Authentication failed. Please check your credentials.';
      case '403':
        return 'Access denied. Please contact support if this continues.';
      case '422':
        return 'Invalid email format. Please enter a valid email address.';
      case '429':
        return 'Too many login attempts. Please wait a few minutes and try again.';
      case '500':
        return 'Server error. Please try again in a few moments.';
      default:
        if (e.message.contains('Network') == true) {
          return 'Network error. Please check your connection and try again.';
        }
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? role,
  }) async {
    // Check connectivity first
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
          'role': role ?? 'buyer',
        },
      );

      if (response.user == null && response.session == null) {
        throw Exception('Registration failed. Please try again.');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Registration failed: ${error.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    // Check connectivity first
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw Exception('Invalid email or password. Please try again.');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Authentication failed: ${error.toString()}');
    }
  }

  /// Sign in with phone and password
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    // Check connectivity first
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      // For phone authentication, we'll use email field with phone as identifier
      final response = await _client.auth.signInWithPassword(
        email: phone,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw Exception('Invalid phone number or password. Please try again.');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Phone authentication failed: ${error.toString()}');
    }
  }

  /// OAuth sign-in with Google
  Future<bool> signInWithGoogle() async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      return await _client.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Google sign-in failed: ${error.toString()}');
    }
  }

  /// OAuth sign-in with Apple
  Future<bool> signInWithApple() async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      return await _client.auth.signInWithOAuth(OAuthProvider.apple);
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Apple sign-in failed: ${error.toString()}');
    }
  }

  /// OAuth sign-in with Facebook
  Future<bool> signInWithFacebook() async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      return await _client.auth.signInWithOAuth(OAuthProvider.facebook);
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Facebook sign-in failed: ${error.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      // Log error but don't throw - sign out should always succeed for UX
      print('Sign out completed with warning: $error');

      // Even if there's an error, we consider the sign out successful
      // The user's local session is cleared regardless
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Password reset failed: ${error.toString()}');
    }
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Password update failed: ${error.toString()}');
    }
  }

  /// Update user email
  Future<UserResponse> updateEmail(String newEmail) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Email update failed: ${error.toString()}');
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get user metadata
  Map<String, dynamic>? getUserMetadata() {
    return currentUser?.userMetadata;
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Profile update failed: ${error.toString()}');
    }
  }

  /// Get user role from metadata
  String? getUserRole() {
    final metadata = getUserMetadata();
    return metadata?['role'] as String?;
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    final userRole = getUserRole();
    return userRole == role;
  }

  /// Refresh current session
  Future<AuthResponse> refreshSession() async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      throw Exception(
          'No internet connection. Please check your network and try again.');
    }

    try {
      final response = await _client.auth.refreshSession();
      return response;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (error) {
      if (error.toString().contains('NetworkException') ||
          error.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your connection and try again.');
      }
      throw Exception('Session refresh failed: ${error.toString()}');
    }
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate Brunei phone number format
  bool isValidBruneiPhone(String phone) {
    return RegExp(r'^\+673[2-8]\d{6}$').hasMatch(phone);
  }
}
