import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/services/api_service.dart';

class AiChatSheet extends StatefulWidget {
  final bool isDark;
  final String? currentTicker; // 🚨 Add this line
  const AiChatSheet({super.key, required this.isDark, this.currentTicker});
  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Stores the chat history. 'role' is either 'user' or 'ai'.
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hello! I am your HybStockAdvisor AI. Ask me about any Nigerian stock, market trends, or why a specific recommendation was made!',
    },
  ];

  // Saved messages loaded from Hive (previous session)
  List<Map<String, String>> _savedMessages = [];

  bool _isTyping = false;

  static const String _historyBoxName = 'chat_history';
  static const String _historyKey = 'messages';
  static const int _maxHistory = 20;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Add User Message
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    // 2. Call Python Backend (Gemini)
    final response = await ApiService.sendChatMessage(
      text,
      currentTicker: widget.currentTicker,
    );

    // 3. Add AI Response
    setState(() {
      _isTyping = false;
      _messages.add({'role': 'ai', 'text': response});
    });
    _scrollToBottom();
    _persistHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final box = await Hive.openBox(_historyBoxName);
      final raw = box.get(_historyKey);
      if (raw != null && raw is List && raw.isNotEmpty) {
        final loaded = raw
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        if (mounted) setState(() => _savedMessages = loaded);
      }
    } catch (_) {}
  }

  void _persistHistory() {
    // Skip the static welcome bubble (index 0), keep last _maxHistory messages
    final toSave = _messages.skip(1).toList();
    final capped = toSave.length > _maxHistory
        ? toSave.sublist(toSave.length - _maxHistory)
        : toSave;
    Hive.openBox(_historyBoxName).then((box) => box.put(_historyKey, capped));
  }

  void _showHistorySheet() {
    final bgColor = widget.isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF2F4F7);
    final cardColor = widget.isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.history, color: const Color(0xFF0A3D62)),
                  const SizedBox(width: 8),
                  Text(
                    'Previous Chat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Messages or empty state
            Expanded(
              child: _savedMessages.isEmpty
                  ? Center(
                      child: Text(
                        'No previous chat history.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedMessages.length,
                      itemBuilder: (_, index) {
                        final msg = _savedMessages[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF0A3D62)
                                  : cardColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isUser ? 14 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 14),
                              ),
                            ),
                            child: Text(
                              msg['text']!,
                              style: TextStyle(
                                color: isUser ? Colors.white : textColor,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Resume button
            if (_savedMessages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _messages
                          ..clear()
                          ..add({
                            'role': 'ai',
                            'text':
                                'Hello! I am your HybStockAdvisor AI. Ask me about any Nigerian stock, market trends, or why a specific recommendation was made!',
                          })
                          ..addAll(_savedMessages);
                      });
                      _scrollToBottom();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D62),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Resume Conversation',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF2F4F7);
    final cardColor = widget.isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Container(
      height:
          MediaQuery.of(context).size.height * 0.85, // Takes up 85% of screen
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle & Header
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF0A3D62)),
                const SizedBox(width: 8),
                Text(
                  'Lexi - Your AI Stock Advisor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _savedMessages.isEmpty ? null : _showHistorySheet,
                  icon: Icon(
                    Icons.history,
                    color: _savedMessages.isEmpty
                        ? Colors.grey[400]
                        : const Color(0xFF0A3D62),
                  ),
                  tooltip: 'Previous chat',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(widget.isDark);
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0A3D62) : cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : textColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom +
                  20, // Adjusts for keyboard
            ),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        hintText: "Ask about a stock...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A3D62),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D3E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0A3D62),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Lexi is thinking...",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
