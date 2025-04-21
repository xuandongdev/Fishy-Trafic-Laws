class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
class LawSearchResult {
  final String sohieu;
  final String tenvanban;
  final String noidung;

  LawSearchResult({required this.sohieu, required this.tenvanban, required this.noidung});

  factory LawSearchResult.fromJson(Map<String, dynamic> json) {
    return LawSearchResult(
      sohieu: json['sohieuvanban'],
      tenvanban: json['tenvanban'],
      noidung: json['noidung'],
    );
  }
}
