import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  final int receiverId;
  final String receiverName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];
  Timer? _poller;
  int? _meId;

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadInitial();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _pollNew());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/messages', query: {'user_id': '${widget.receiverId}'});
      if (res is Map<String, dynamic> && res['data'] is List) {
        final data = (res['data'] as List).cast<Map<String, dynamic>>();
        setState(() => _messages = data);
        _scrollToBottom();
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pollNew() async {
    if (_messages.isEmpty) return;
    final lastId = _messages.last['id'] as num?;
    if (lastId == null) return;

    try {
      final res = await _api.get('/messages', query: {
        'user_id': '${widget.receiverId}',
        'after_id': '$lastId',
      });
      if (res is List && res.isNotEmpty) {
        setState(() => _messages.addAll(res.cast<Map<String, dynamic>>()));
        _scrollToBottom();
      }
    } catch (_) {
      // ignore polling errors
    }
  }

  Future<void> _loadMe() async {
    try {
      final res = await _api.get('/profile');
      if (res is Map<String, dynamic>) {
        _meId = (res['id'] as num?)?.toInt();
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final res = await _api.post('/send-message', body: {
        'receiver_id': widget.receiverId,
        'message': text,
      });

      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        setState(() => _messages.add(Map<String, dynamic>.from(res['data'] as Map)));
      }
      _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMe(Map<String, dynamic> msg) {
    if (_meId == null) return false;
    final senderId = (msg['sender_id'] as num?)?.toInt();
    return senderId == _meId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: widget.receiverName, subtitle: 'চ্যাট'),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = _isMe(msg);
                      final text = msg['message']?.toString() ?? '';
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(text),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'মেসেজ লিখুন'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
