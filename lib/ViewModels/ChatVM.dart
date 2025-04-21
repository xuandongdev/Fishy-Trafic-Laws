import 'package:flutter/material.dart';
import 'package:fishy/Models/ChatMessages.dart';
import 'package:fishy/Services/ChatService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishy/Services/AuthService.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  final ChatService chatService = ChatService();
  bool _isTyping = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isTyping => _isTyping;

  void setTyping(bool value) {
    _isTyping = value;
    notifyListeners();
  }
  void clearMessages() {
    messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String? userMessage) async {
    if (userMessage == null || userMessage.trim().isEmpty) return;

    messages.add(ChatMessage(text: userMessage, isUser: true));
    setTyping(true);
    try {
      final isTrafficLaw = await chatService.classifyTrafficIntent(userMessage);
      String botResponse = "";
      if (isTrafficLaw) {
        final rasaResponseFuture = chatService.getRasaResponse(userMessage);
        final timeoutFuture = Future.delayed(Duration(seconds: 30), () {
          print("Timeout: Không nhận được phản hồi từ Rasa sau 30 giây.");
          return [];
        });

        final dynamic responseData = await Future.any([
          rasaResponseFuture,
          timeoutFuture,
        ]);

        print("Dữ liệu responseData từ Rasa: $responseData");

        if (responseData is List && responseData.isNotEmpty) {
          final buffer = StringBuffer();

          for (var message in responseData) {
            if (message['text'] != null) {
              buffer.writeln(message['text']);
            }
          }
          botResponse = buffer.toString();
        } else {
          print("Rasa không trả về phản hồi hợp lệ.");
          botResponse = await _searchByEmbeddingOrKeyword(userMessage);
        }
      } else {
        botResponse = await chatService.getBotResponse(userMessage);
        print("Phản hồi từ Gemini (không phải luật): $botResponse");
      }
      messages.add(ChatMessage(text: botResponse, isUser: false));
      await _saveChatHistory(userMessage, botResponse);
    } finally {
      setTyping(false);
      notifyListeners();
    }
  }

  Future<String> _searchByEmbeddingOrKeyword(String userMessage) async {
    print("Chuyển sang phương thức tìm kiếm khác (embedding/keyword).");
    List<Map<String, dynamic>> embeddingResults = [];
    final queryEmbedding = await chatService.generateEmbedding(userMessage);
    if (queryEmbedding != null) {
      embeddingResults = await searchLawEmbeddings(queryEmbedding);
    }

    if (embeddingResults.isEmpty) {
      embeddingResults = await searchLawKeywords(userMessage);
    }

    if (embeddingResults.isNotEmpty) {
      return await formatLawResponse(embeddingResults);
    } else {
      final fallbackPrompt = """
Người dùng hỏi: "$userMessage"
Không tìm thấy văn bản luật cụ thể trong cơ sở dữ liệu. Hãy trả lời dựa trên kiến thức chung về luật giao thông Việt Nam. Trả lời tự nhiên, luôn bằng tiếng Việt.
""";
      return await chatService.getBotResponse(fallbackPrompt);
    }
  }

  Future<void> _saveChatHistory(String userMessage, String botResponse) async {
    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        final currentUser = await AuthService().getCurrentUser();
        final userId = currentUser?['userid'];

        if (userId != null) {
          await _supabase.from('lich_su_tro_chuyen').insert({
            'userid': userId,
            'cauhoi': userMessage,
            'traloi': botResponse,
          });
          print('Lưu lịch sử trò chuyện thành công.');
        } else {
          print('Không lấy được userid từ người dùng.');
        }
      } catch (e) {
        print('Lỗi khi lưu lịch sử trò chuyện: $e');
      }
    } else {
      print('Người dùng chưa đăng nhập, không lưu lịch sử trò chuyện.');
    }
  }

  Future<List<Map<String, dynamic>>> searchLawKeywords(String question) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'tra_cuu_van_ban',
        params: {'tukhoa': question},
      );

      if (response is List) {
        return response.map<Map<String, dynamic>>((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return {
            'sohieu': map['sohieuvanban']?.toString() ?? 'N/A',
            'noidung': map['noidung']?.toString() ?? '',
            'sothutund': map['id'] as int?,
          };
        }).toList();
      } else {
        print(
          "[searchLawKeywords] Invalid response type: ${response?.runtimeType}",
        );
        return [];
      }
    } catch (e) {
      print("[searchLawKeywords] Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchLawEmbeddings(
    List<double> queryEmbedding,
  ) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'tra_cuu_embedding',
        params: {'query_embedding': queryEmbedding, 'match_count': 5},
      );

      if (response is List) {
        return response.map<Map<String, dynamic>>((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return {
            'sohieu': map['sohieu']?.toString(),
            'noidung': map['noidung']?.toString(),
            'dotuongdong': (map['dotuongdong'] as num?)!.toDouble() >= 0.75,
            'sothutund': map['id'] as int?,
          };
        }).toList();
      } else {
        print(
          "[searchLawEmbeddings] Invalid response type: ${response?.runtimeType}",
        );
        return [];
      }
    } catch (e) {
      print("[searchLawEmbeddings] Error: $e");
      return [];
    }
  }

  Future<String> getPathWithContent(int startId) async {
    final client = Supabase.instance.client;
    List<String> titleSegments = [];
    String? parentContent;

    int? currentId = startId;
    int loopCount = 0;

    while (currentId != null) {
      final response =
          await client
              .from('noidung')
              .select('sothutund, sothutund_cha, noidung')
              .eq('sothutund', currentId)
              .maybeSingle();

      if (response != null) {
        final noidung = response['noidung']?.toString() ?? '';
        final shortTitle = extractShortTitle(noidung);

        if (loopCount == 1) {
          parentContent = noidung;
        } else if (loopCount > 1) {
          titleSegments.insert(0, shortTitle);
        }

        currentId = response['sothutund_cha'];
        loopCount++;
      } else {
        break;
      }
    }

    final hierarchy = titleSegments.join(", ");
    final parentText = parentContent != null ? "$parentContent\n" : "";

    return "$hierarchy${hierarchy.isNotEmpty ? ', ' : ''}$parentText";
  }

  String extractShortTitle(String fullText) {
    final firstLine = fullText.trim().split('\n').first;
    final regex = RegExp(
      r'^(Chương\s+[IVXLCDM]+|Mục\s+\d+|Điều\s+\d+|Khoản\s+\d+|Điểm\s+\w+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(firstLine);
    return match?.group(0)?.toUpperCase() ?? '';
  }

  Future<String> formatLawResponse(
    List<Map<String, dynamic>> lawResults,
  ) async {
    if (lawResults.isEmpty) return "Không tìm thấy văn bản nào phù hợp.";

    final buffer = StringBuffer(
      "Các kết quả liên quan mà FISHY đã tìm được:\n",
    );

    for (var result in lawResults) {
      final sohieu = result['sohieu'] ?? 'N/A';
      final noidung = result['noidung'] ?? '';
      final sothutund = result['sothutund'];

      buffer.writeln("\n🔹=======================🔹");
      buffer.writeln("🔹 *(Nguồn: Văn bản $sohieu)*");

      if (sothutund != null) {
        final hierarchyFull = await getPathWithContent(sothutund);
        if (hierarchyFull.isNotEmpty) {
          buffer.writeln("🔹${hierarchyFull.trim()}");
        }
      }

      if (noidung.isNotEmpty) {
        buffer.writeln("   $noidung");
      }
    }

    return buffer.toString().trim();
  }
}
