import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fishy/Configs/Constants.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final GenerativeModel _generativeModel;
  final GenerativeModel _embeddingModel;
  static final String _apiKey = Constants.apiKey;

  ChatService({
    String generativeModelName = 'gemini-1.5-flash',
    String embeddingModelName = 'models/embedding-001',
  })  : _generativeModel = GenerativeModel(model: generativeModelName, apiKey: _apiKey),
        _embeddingModel = GenerativeModel(model: embeddingModelName, apiKey: _apiKey);

  final String rasaBaseUrl = 'http://10.0.2.2:5005';

  Future<bool> classifyTrafficIntent(String userMessage) async {
    final prompt = """
    Phân tích câu hỏi sau đây của người dùng. Câu này có chủ đích hỏi về luật giao thông, quy định giao thông, xử phạt vi phạm giao thông, thủ tục liên quan đến phương tiện giao thông (như đăng kiểm, bằng lái), hoặc các tình huống cụ thể khi tham gia giao thông không?

    Chỉ trả lời bằng một từ duy nhất: 'CÓ' nếu đúng là hỏi về giao thông, hoặc 'KHÔNG' nếu là chủ đề khác hoặc trò chuyện thông thường.

    Câu hỏi của người dùng: "$userMessage"
    """;

    try {
      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ], generationConfig: GenerationConfig(maxOutputTokens: 5, temperature: 0.1));

      final result = response.text?.trim().toUpperCase() ?? "KHÔNG";
      print("Gemini intent classify: $result");
      return result == "CÓ";
    } catch (e) {
      print("Error classifyTrafficIntent: $e");
      return false;
    }
  }

  Future<List<double>?> generateEmbedding(String text) async {
    try {
      print("Generating embedding for: $text");
      final response = await _embeddingModel.embedContent(Content.text(text));
      return response.embedding.values;
    } catch (e) {
      print("Error generating embedding: $e");
      return null;
    }
  }

  Future<String> getBotResponse(String prompt) async {
    try {
      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ], generationConfig: GenerationConfig(temperature: 0.7));

      return response.text ?? "Xin lỗi, tôi chưa thể đưa ra câu trả lời.";
    } catch (e) {
      print("Gemini bot error: $e");
      return "Đã xảy ra lỗi khi kết nối đến AI.";
    }
  }

  Future<List<dynamic>> getRasaResponse(String userMessage) async {
    try {
      final uri = Uri.parse('$rasaBaseUrl/webhooks/rest/webhook');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sender': 'flutter_user', 'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        print("DEBUG - Rasa response: ${response.body}");
        return responseBody;
      } else {
        print("getRasaResponse error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("getRasaResponse error: $e");
      return [];
    }
  }

  Future<RasaIntentResult> classifyWithRasa(String message) async {
    try {
      final uri = Uri.parse('$rasaBaseUrl/model/parse');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final intent = data['intent']['name'] ?? 'unknown';
        final confidence = data['intent']['confidence']?.toDouble() ?? 0.0;
        return RasaIntentResult(intent: intent, confidence: confidence);
      } else {
        print("Rasa classify error: ${response.body}");
        return RasaIntentResult(intent: 'unknown', confidence: 0.0);
      }
    } catch (e) {
      print("classifyWithRasa error: $e");
      return RasaIntentResult(intent: 'unknown', confidence: 0.0);
    }
  }

}

class RasaIntentResult {
  final String intent;
  final double confidence;

  RasaIntentResult({required this.intent, required this.confidence});
}
