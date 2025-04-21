import 'package:supabase_flutter/supabase_flutter.dart';

class Constants {
  static final String apiKey = "AIzaSyCQDCoKqIF_e36LGsg64qMkdD0XdNOTn_Q";
  static final String baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
}
class SupabaseConfig {
  static final String supaUrl = "https://bqrvxbqthhsrswutktvr.supabase.co";
  static final String supaKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxcnZ4YnF0aGhzcnN3dXRrdHZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzNTI1NjAsImV4cCI6MjA1ODkyODU2MH0.G0mLzBZzXKc7fI93Vl5bRLYOCyvLo3pXSop1NH0W0WI";

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
