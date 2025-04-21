import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishy/Configs/Constants.dart';

class EmbeddingService {
  static final SupabaseClient supabase = Supabase.instance.client;

  static Future<List<double>> generateEmbedding(String content) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/embedding-001:embedContent?key=${Constants.apiKey}';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "content": {"parts": [{"text": content}]}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<double>.from(data['embedding']['values']);
    } else {
      throw Exception('Lỗi gọi Gemini: ${response.body}');
    }
  }

  static Future<void> generateAndUpdateAllEmbeddings() async {
    final rows = await supabase
        .from('noidung')
        .select()
        .filter('embedding', 'is', null);

    for (var row in rows) {
      final id = row['sothutund'];
      final content = row['noidung'];

      try {
        final embedding = await generateEmbedding(content);
        await supabase.from('noidung').update({
          'embedding': embedding,
        }).eq('sothutund', id);
      } catch (e) {
        print('Lỗi khi tạo embedding cho sothutund $id: $e');
      }
    }
  }
  static Future<void> generateAndUpdateOneEmbedding(int sothutund, String noidung) async {
    try {
      final embedding = await generateEmbedding(noidung);
      await supabase.from('noidung').update({
        'embedding': embedding,
      }).eq('sothutund', sothutund);
    } catch (e) {
      print('Lỗi khi sinh embedding cho $sothutund: $e');
    }
  }
}
