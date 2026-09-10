import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/logo_loader.dart';

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
      final body = <String, dynamic>{'receiver_id': widget.receiverId};
      if (text != null && text.trim().isNotEmpty) {
        body['message'] = text.trim();
      }
      if (imageUrl != null) {
        body['image'] = imageUrl;
      }
      if (attachmentUrl != null) {
        body['attachment_url'] = attachmentUrl;
      }
      if (attachmentName != null) {
        body['attachment_name'] = attachmentName;
      }
      if (attachmentMime != null) {
        body['attachment_mime'] = attachmentMime;
      }

      final res = await _api.post('/send-message', body: body);

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
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
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
      backgroundColor: const Color(0xfff4f7f6),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: _ChatHeader(title: widget.receiverName),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: LogoLoader(showLabel: true))
                : _error != null
                ? Center(child: Text(_error!))
                : _messages.isEmpty
                ? const Center(child: Text('কোনো মেসেজ নেই'))
                : RefreshIndicator(
                    onRefresh: _loadInitial,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = _isMe(msg);
                        final text = msg['message']?.toString() ?? '';
                        final time = _formatTime(msg['created_at']?.toString());
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? scheme.primary : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 5),
                                bottomRight: Radius.circular(isMe ? 5 : 18),
                              ),
                              border: Border.all(
                                color: isMe
                                    ? scheme.primary
                                    : const Color(0xffe5e7eb),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (text.trim().isNotEmpty)
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe
                                          ? scheme.onPrimary
                                          : const Color(0xff1f2937),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (msg['image'] != null ||
                                    msg['attachment_url'] != null) ...[
                                  if (text.trim().isNotEmpty)
                                    const SizedBox(height: 8),
                                  _buildAttachment(msg, scheme),
                                ],
                                if (time.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe
                                              ? scheme.onPrimary.withValues(
                                                  alpha: 0.72,
                                                )
                                              : const Color(0xff9ca3af),
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          _statusLabel(msg),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMe
                                                ? scheme.onPrimary.withValues(
                                                    alpha: 0.72,
                                                  )
                                                : const Color(0xff9ca3af),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: const Color(0xffe5e7eb))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _uploading ? null : _openAttachmentSheet,
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xff006a4e),
                  ),
                  icon: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: LogoLoader(size: 20),
                        )
                      : const Icon(Icons.attach_file_rounded),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'মেসেজ লিখুন',
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xffe5e7eb)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xff006a4e)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff006a4e),
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
    );
  }
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

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xff1f2937),
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xffe6f1ee),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: Text(
              title.isNotEmpty ? title.characters.first : 'U',
              style: const TextStyle(
                color: Color(0xff006a4e),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff1f2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'চ্যাট',
                style: TextStyle(color: Color(0xff4b5563), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
