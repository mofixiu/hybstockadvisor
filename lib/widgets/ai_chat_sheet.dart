import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ChatMessage {
  final String role;
  final String text;

  const _ChatMessage({required this.role, required this.text});

  Map<String, String> toJson() => {'role': role, 'text': text};

  static _ChatMessage? fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final text = json['text'];
    if (role is! String || text is! String) return null;
    return _ChatMessage(role: role, text: text);
  }
}

class AiChatScreen extends StatelessWidget {
  final bool isDark;
  final String? currentTicker;
  final String? initialMessage;

  const AiChatScreen({
    super.key,
    required this.isDark,
    this.currentTicker,
    this.initialMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AiChatSheet(
          isDark: isDark,
          currentTicker: currentTicker,
          initialMessage: initialMessage,
        ),
      ),
    );
  }
}

class AiChatSheet extends StatefulWidget {
  final bool isDark;
  final String? currentTicker;
  final String? initialMessage;
  const AiChatSheet({
    super.key,
    required this.isDark,
    this.currentTicker,
    this.initialMessage,
  });
  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hello! I am Lexi - Your AI stock advisor. Ask me about any Nigerian stock, market trends, or why a specific recommendation was made!',
    },
  ];

  List<Map<String, String>> _savedMessages = [];

  bool _isTyping = false;
  bool _hasInjectedInitialMessage = false;

  static const String _historyKey = 'messages';
  static const int _maxHistory = 10;

  @override
  void initState() {
    super.initState();
    _loadHistory().whenComplete(_seedInitialMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();
    _persistHistory();

    final response = await ApiService.sendChatMessage(
      text,
      currentTicker: widget.currentTicker,
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add({'role': 'ai', 'text': response});
    });
    _scrollToBottom();
    _persistHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = decoded
          .map((e) => _ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .whereType<_ChatMessage>()
          .map((e) => e.toJson())
          .toList();
      if (!mounted) return;
      setState(() {
        _savedMessages = loaded;
        _messages
          ..clear()
          ..add({
            'role': 'ai',
            'text':
                'Hello! I am Lexi - Your AI stock advisor. Ask me about any Nigerian stock, market trends, or why a specific recommendation was made!',
          })
          ..addAll(loaded);
      });
      _scrollToBottom();
    } catch (_) {}
  }

  void _seedInitialMessage() {
    final initial = widget.initialMessage?.trim();
    if (initial == null || initial.isEmpty || _hasInjectedInitialMessage) {
      return;
    }
    _hasInjectedInitialMessage = true;
    _messageController.text = initial;
    _sendMessage();
  }

  Future<void> _persistHistory() async {
    final toSave = _messages.skip(1).toList();
    final capped = toSave.length > _maxHistory
        ? toSave.sublist(toSave.length - _maxHistory)
        : toSave;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(capped.map((e) => e).toList());
    await prefs.setString(_historyKey, encoded);
  }

  void _showHistorySheet() {
    final isDark = widget.isDark;
    final glassColor = isDark
        ? Colors.black.withOpacity(0.8)
        : Colors.white.withOpacity(0.92);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.35);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.85);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: glassColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 1.2),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Color(0xFF2979FF)),
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
                        child: Icon(Icons.close, color: isDark ? Colors.white60 : Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.transparent),
                Expanded(
                  child: _savedMessages.isEmpty
                      ? Center(
                          child: Text(
                            'No previous chat history.',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 14),
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
                                  color: isUser ? const Color(0xFF0A3D62) : cardColor,
                                  border: isUser
                                      ? null
                                      : Border.all(color: borderColor, width: 1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  msg['text']!,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : textColor,
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
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
                                    'Hello! I am Lexi - Your AI stock advisor. Ask me about any Nigerian stock, market trends, or why a specific recommendation was made!',
                              })
                              ..addAll(_savedMessages);
                          });
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _scrollToBottom();
                          });
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final glassColor = isDark
        ? Colors.black.withOpacity(0.8)
        : Colors.white.withOpacity(0.92);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.35);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.85);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final inputBgColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.03);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 1.2),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF2979FF)),
                    const SizedBox(width: 8),
                    Text(
                      'Lexi - AI Advisor',
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
                            ? (isDark ? Colors.white24 : Colors.grey[400])
                            : const Color(0xFF2979FF),
                      ),
                      tooltip: 'Previous chat',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: isDark ? Colors.white60 : Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator(isDark);
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
                          border: isUser
                              ? null
                              : Border.all(color: borderColor, width: 1),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUser ? 18 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : textColor,
                            fontSize: 14.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: BoxDecoration(
                  color: glassColor,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: textColor, fontSize: 14.5),
                          decoration: InputDecoration(
                            hintText: "Ask Lexi about a stock...",
                            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[500]),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3D62),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A3D62).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.85);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.35);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
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
                color: Color(0xFF2979FF),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Lexi is typing...",
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
