import 'package:flutter/material.dart';

import '../services/event_chatbot_service.dart';

class EventChatbotScreen extends StatefulWidget {
  const EventChatbotScreen({super.key});

  @override
  State<EventChatbotScreen> createState() => _EventChatbotScreenState();
}

class _EventChatbotScreenState extends State<EventChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = EventChatbotService();
  final List<ChatTurn> _messages = const [
    ChatTurn(
      text:
          'Xin chao, minh la Poki. Ban co the hoi ve su kien hoac cac cau hoi chung nhu ngay thang, meo hoc tap va chuan bi su kien.',
      isUser: false,
    ),
  ].toList();

  bool _isSending = false;

  final List<String> _suggestions = const [
    'Su kien sap toi dien ra khi nao?',
    'Su kien nao co phien gan nhat?',
    'Dia diem cua cac phien la o dau?',
    'Co can mang theo laptop khong?',
    'Hom nay la ngay bao nhieu?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatTurn(text: text, isUser: true));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final answer = await _service.ask(
        question: text,
        history: _messages.length > 1
            ? _messages.sublist(0, _messages.length - 1)
            : const [],
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatTurn(text: answer, isUser: false));
      });
    } on EventChatbotException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatTurn(
            text: error.message,
            isUser: false,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatTurn(
            text: 'Poki dang gap su co khong xac dinh. Vui long thu lai sau.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 12),
        _buildSuggestions(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: _messages.length + (_isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isSending && index == _messages.length) {
                return const _TypingBubble();
              }
              return _ChatBubble(message: _messages[index]);
            },
          ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.smart_toy_outlined, color: Colors.green),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tro ly ao',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Event Chatbot Assistant (Poki)',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: _isSending ? null : () => _sendMessage(suggestion),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.green.shade200),
            labelStyle: TextStyle(color: Colors.green.shade800),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Hoi ve su kien, dia diem, thoi gian...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: _isSending ? null : () => _sendMessage(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatTurn message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Poki dang tra loi...'),
          ],
        ),
      ),
    );
  }
}
