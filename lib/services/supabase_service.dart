import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.');
    }

    // Check network connectivity before initializing
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print(
          'Warning: No network connection detected during Supabase initialization');
      // Continue initialization anyway - offline support
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: false, // Set to true for debugging network issues
      );

      print('Supabase initialized successfully');
    } catch (e) {
      print('Supabase initialization failed: $e');

      if (e.toString().contains('network') ||
          e.toString().contains('Network') ||
          e.toString().contains('connection')) {
        throw Exception(
            'Network error during initialization. Please check your internet connection and try again.');
      }

      rethrow;
    }
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Check if Supabase is initialized
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Try to make a simple request to test the connection
      await client.auth.getUser();
      return true;
    } catch (e) {
      print('Supabase connection test failed: $e');
      return false;
    }
  }
}