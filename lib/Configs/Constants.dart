import 'package:supabase_flutter/supabase_flutter.dart';

class Constants {
  static final String apiKey = hehe;
  static final String baseUrl = hehe;
}
class SupabaseConfig {
  static final String supaUrl = hehe;
  static final String supaKey = hehe;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      await Supabase.initialize(
        url: supaUrl,
        anonKey: supaKey,
      );
      _isInitialized = true;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
