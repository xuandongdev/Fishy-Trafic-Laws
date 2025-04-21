  import 'package:flutter/material.dart';
  import 'package:fishy/Themes/ThemeData.dart';
  import 'package:fishy/ViewModels/ChatVM.dart';
  import 'package:provider/provider.dart';
  import 'package:fishy/Widgets/CustomAppBar.dart';
  import '../Widgets/TypingIndicator.dart';

  class ChatScreen extends StatelessWidget {
    const ChatScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return CustomAppBar(
        title: 'Fishy Traffic Laws',
        body: const ChatMessages(),
      );
    }
  }

  class ChatMessages extends StatefulWidget {
    const ChatMessages({super.key});

    @override
    _ChatMessagesState createState() => _ChatMessagesState();
  }

  class _ChatMessagesState extends State<ChatMessages> {
    final TextEditingController textController = TextEditingController();
    final ScrollController _scrollController = ScrollController();

    @override
    Widget build(BuildContext context) {
      return Consumer<ChatViewModel>(
        builder: (context, chatVM, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: chatVM.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatVM.messages[index];
                    return Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Column(
                          crossAxisAlignment: message.isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(maxWidth: 250),
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? AppTheme.navyBlue
                                    : Colors.blueGrey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  color: message.isUser
                                      ? Colors.white
                                      : Colors.black87,

                                ),
                                softWrap: true,
                                textAlign: TextAlign.left,

                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.only(right: 10, left: 10),
                              child: Text(
                                _formatTime(message.timestamp),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (chatVM.isTyping)
                const TypingIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (value) => _sendMessage(chatVM),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _sendMessage(chatVM),
                      icon: const Icon(Icons.send, color: AppTheme.navyBlue),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    void _sendMessage(ChatViewModel chatVM) {
      final userMessage = textController.text.trim();
      if (userMessage.isEmpty) return;
      chatVM.sendMessage(userMessage);
      textController.clear();
    }

    String _formatTime(DateTime? timestamp) {
      if (timestamp == null) return "Unknown time";
      return "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
    }

    @override
    void dispose() {
      textController.dispose();
      _scrollController.dispose();
      super.dispose();
    }
  }
