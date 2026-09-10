import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/logo_loader.dart';

const _chatBg = Color(0xFFF6F8F5);
const _chatGreen = Color(0xFF00765B);
const _chatBorder = Color(0xFFE2E8E2);
const _chatText = Color(0xFF17251F);
const _chatMuted = Color(0xFF68746E);

InputDecorationTheme _chatInputTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: _chatBorder),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: _chatGreen, width: 1.4),
    ),
    hintStyle: const TextStyle(color: Color(0xFF9AA59F), fontSize: 13),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  final int receiverId;
  final String receiverName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatPageHeader extends StatelessWidget {
  const _ChatPageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: _chatBg,
          border: Border(bottom: BorderSide(color: _chatBorder)),
        ),
        child: Row(
          children: [
            _ChatHeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE8F4EF),
              child: Text(
                title.isNotEmpty ? title[0] : 'U',
                style: const TextStyle(
                  color: _chatGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _chatText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _chatMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeaderButton extends StatelessWidget {
  const _ChatHeaderButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: _chatBorder),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: _chatGreen, size: 18),
      ),
    ),
  );
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  static const _dotAnimDuration = Duration(milliseconds: 900);

  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  String? _error;
  List<Map<String, dynamic>> _messages = [];
  final Set<int> _messageIds = {};
  Timer? _poller;
  Timer? _typingPoller;
  Timer? _typingDebounce;
  bool _otherTyping = false;
  bool _typingSent = false;
  int? _meId;
  bool _shouldAutoScroll = true;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: _dotAnimDuration,
    );
    _loadMe().then((_) => _loadInitial());
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _pollNew());
    _typingPoller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollTyping(),
    );
    _messageController.addListener(_handleTypingChange);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _poller?.cancel();
    _typingPoller?.cancel();
    _typingDebounce?.cancel();
    _sendTyping(false);
    _dotController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(
        '/messages',
        query: {'user_id': '${widget.receiverId}'},
      );
      if (res is Map<String, dynamic> && res['data'] is List) {
        final data = (res['data'] as List).cast<Map<String, dynamic>>();
        _messageIds
          ..clear()
          ..addAll(
            data.map((m) => (m['id'] as num?)?.toInt()).whereType<int>(),
          );
        setState(() => _messages = data);
        _scrollToBottom();
      }
    } catch (_) {
      _error = 'মেসেজ লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pollNew() async {
    if (_messages.isEmpty) return;
    final lastId = _messages.last['id'] as num?;
    if (lastId == null) return;

    try {
      final res = await _api.get(
        '/messages',
        query: {'user_id': '${widget.receiverId}', 'after_id': '$lastId'},
      );
      if (res is List && res.isNotEmpty) {
        final fresh = <Map<String, dynamic>>[];
        for (final raw in res.cast<Map<String, dynamic>>()) {
          final id = (raw['id'] as num?)?.toInt();
          if (id != null && !_messageIds.contains(id)) {
            _messageIds.add(id);
            fresh.add(raw);
          }
        }
        if (fresh.isNotEmpty) {
          setState(() => _messages.addAll(fresh));
        }
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
        if (mounted) {
          setState(() {});
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    await _sendMessage(text: text);
  }

  Future<void> _sendMessage({
    String? text,
    String? imageUrl,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentMime,
  }) async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      final res = await _api.post(
        '/send-message',
        body: {
          'receiver_id': widget.receiverId,
          if (text != null && text.trim().isNotEmpty) 'message': text.trim(),
          ...?imageUrl == null ? null : {'image': imageUrl},
          ...?attachmentUrl == null ? null : {'attachment_url': attachmentUrl},
          ...?attachmentName == null
              ? null
              : {'attachment_name': attachmentName},
          ...?attachmentMime == null
              ? null
              : {'attachment_mime': attachmentMime},
        },
      );

      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        final msg = Map<String, dynamic>.from(res['data'] as Map);
        final id = (msg['id'] as num?)?.toInt();
        if (id == null || !_messageIds.contains(id)) {
          if (id != null) {
            _messageIds.add(id);
          }
          setState(() => _messages.add(msg));
        }
      }
      _messageController.clear();
      _sendTyping(false);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('মেসেজ পাঠানো যায়নি')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!_shouldAutoScroll) return;
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

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final suffix = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $suffix';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _handleAttachmentPick(FileType type) async {
    if (_uploading || _sending) return;
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      final res = await _api.postMultipart(
        '/messages/upload',
        files: {'file': path},
      );
      if (res is Map<String, dynamic>) {
        final url = res['url']?.toString();
        final name = res['name']?.toString();
        final mime = res['mime']?.toString();
        if (url != null && url.isNotEmpty) {
          final isImage = mime != null && mime.startsWith('image/');
          await _sendMessage(
            imageUrl: isImage ? url : null,
            attachmentUrl: isImage ? null : url,
            attachmentName: isImage ? null : name,
            attachmentMime: isImage ? null : mime,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ফাইল আপলোড করা যায়নি')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('ছবি যোগ করুন'),
              onTap: () {
                Navigator.of(context).pop();
                _handleAttachmentPick(FileType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: const Text('ফাইল যোগ করুন'),
              onTap: () {
                Navigator.of(context).pop();
                _handleAttachmentPick(FileType.any);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(Map<String, dynamic> msg) {
    final seen = msg['seen'] == true;
    if (seen) return 'দেখা হয়েছে';
    if (msg['delivered_at'] != null) return 'ডেলিভার্ড';
    return 'সেন্ট';
  }

  Future<void> _sendTyping(bool isTyping) async {
    if (_typingSent == isTyping) return;
    _typingSent = isTyping;
    try {
      await _api.post(
        '/messages/typing',
        body: {'receiver_id': widget.receiverId, 'is_typing': isTyping},
      );
    } catch (_) {
      // ignore
    }
  }

  void _handleTypingChange() {
    final hasText = _messageController.text.trim().isNotEmpty;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 450), () {
      _sendTyping(hasText);
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    _shouldAutoScroll = (max - pos) < 120;
  }

  Future<void> _pollTyping() async {
    try {
      final res = await _api.get(
        '/messages/typing-status',
        query: {'user_id': '${widget.receiverId}'},
      );
      if (res is Map<String, dynamic>) {
        final typing = res['is_typing'] == true;
        if (typing != _otherTyping && mounted) {
          setState(() => _otherTyping = typing);
          if (typing) {
            _dotController.repeat();
          } else {
            _dotController.stop();
          }
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Widget _buildAttachment(Map<String, dynamic> msg, ColorScheme scheme) {
    final imageUrl = msg['image']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openImageViewer(imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 220,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final attachmentUrl = msg['attachment_url']?.toString();
    if (attachmentUrl == null || attachmentUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final mime = msg['attachment_mime']?.toString() ?? '';
    final lowerUrl = attachmentUrl.toLowerCase();
    final isImage =
        mime.startsWith('image/') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.gif');

    if (isImage) {
      return GestureDetector(
        onTap: () => _openImageViewer(attachmentUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            attachmentUrl,
            width: 220,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final name = msg['attachment_name']?.toString() ?? 'ফাইল';
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(attachmentUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _chatBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined, color: _chatGreen),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _chatText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _chatBg,
      body: Theme(
        data: Theme.of(
          context,
        ).copyWith(inputDecorationTheme: _chatInputTheme()),
        child: Column(
          children: [
            _ChatPageHeader(title: widget.receiverName, subtitle: 'চ্যাট'),
            Expanded(
              child: _loading
                  ? const Center(child: LogoLoader(showLabel: true))
                  : _error != null
                  ? _ChatEmptyState(text: _error!, icon: Icons.error_outline)
                  : _messages.isEmpty
                  ? const _ChatEmptyState(
                      text: 'কোনো মেসেজ নেই',
                      icon: Icons.chat_bubble_outline_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = _isMe(msg);
                          final text = msg['message']?.toString() ?? '';
                          final time = _formatTime(
                            msg['created_at']?.toString(),
                          );
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? _chatGreen : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 6),
                                    bottomRight: Radius.circular(isMe ? 6 : 18),
                                  ),
                                  border: isMe
                                      ? null
                                      : Border.all(color: _chatBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (text.trim().isNotEmpty)
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : _chatText,
                                          height: 1.35,
                                        ),
                                      ),
                                    if (msg['image'] != null ||
                                        msg['attachment_url'] != null) ...[
                                      if (text.trim().isNotEmpty)
                                        const SizedBox(height: 8),
                                      _buildAttachment(msg, scheme),
                                    ],
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isMe
                                                  ? Colors.white.withValues(
                                                      alpha: 0.75,
                                                    )
                                                  : _chatMuted,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              _statusLabel(msg),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _otherTyping
                  ? Container(
                      key: const ValueKey('typing'),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                      child: _TypingDots(
                        color: scheme.onSurfaceVariant,
                        controller: _dotController,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: _chatBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _uploading ? null : _openAttachmentSheet,
                    icon: _uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: LogoLoader(size: 20),
                          )
                        : const Icon(Icons.attach_file_rounded),
                    color: _chatGreen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'মেসেজ লিখুন',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: _chatGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: LogoLoader(size: 20),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _chatBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _chatGreen, size: 42),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _chatMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.color, required this.controller});

  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        double dotOpacity(double start) {
          final phase = (t - start) % 1.0;
          final v = 0.3 + (0.7 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0));
          return v;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(dotOpacity(0.0)),
            const SizedBox(width: 4),
            _dot(dotOpacity(0.2)),
            const SizedBox(width: 4),
            _dot(dotOpacity(0.4)),
          ],
        );
      },
    );
  }

  Widget _dot(double opacity) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
