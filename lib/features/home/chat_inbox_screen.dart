import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'chat_screen.dart';

const _chatBg = Color(0xFFF6F8F5);
const _chatGreen = Color(0xFF00765B);
const _chatBorder = Color(0xFFE2E8E2);
const _chatText = Color(0xFF17251F);
const _chatMuted = Color(0xFF68746E);

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _threads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/messages/inbox');
      if (res is List) {
        _threads = res.cast<Map<String, dynamic>>();
      } else {
        _threads = [];
      }
    } catch (e) {
      _error = 'ইনবক্স লোড করা যাচ্ছে না';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
      return '';
    }
  }

  String _preview(Map<String, dynamic>? last) {
    if (last == null) return 'কোনো বার্তা নেই';
    final text = (last['message'] ?? '').toString().trim();
    if (text.isNotEmpty) return text;
    if ((last['image'] ?? '').toString().isNotEmpty) return 'ছবি পাঠানো হয়েছে';
    if ((last['attachment_url'] ?? '').toString().isNotEmpty) {
      return 'ফাইল পাঠানো হয়েছে';
    }
    return 'কোনো বার্তা নেই';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _chatBg,
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? _ChatEmptyState(text: _error!, icon: Icons.error_outline_rounded)
          : _threads.isEmpty
          ? const _ChatEmptyState(
              text: 'কোনো কথোপকথন নেই',
              icon: Icons.chat_bubble_outline_rounded,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _ChatPageHeader(
                    title: 'মেসেজ ইনবক্স',
                    subtitle: 'সব কথোপকথন',
                    icon: Icons.chat_bubble_rounded,
                    showBack: true,
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(_threads.length, (index) {
                    final item = _threads[index];
                    final name = (item['name'] ?? 'ব্যবহারকারী').toString();
                    final photo = item['photo_url']?.toString();
                    final last = item['last_message'] as Map<String, dynamic>?;
                    final time = _formatTime(last?['created_at']?.toString());
                    final unread = (item['unread_count'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ChatThreadCard(
                        name: name,
                        photo: photo,
                        preview: _preview(last),
                        time: time,
                        unread: unread,
                        onTap: () {
                          final receiverId = (item['user_id'] as num?)?.toInt();
                          if (receiverId == null) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                receiverId: receiverId,
                                receiverName: name,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _ChatPageHeader extends StatelessWidget {
  const _ChatPageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            _ChatHeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _chatText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _chatMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ChatHeaderButton(icon: icon),
        ],
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
        width: 44,
        height: 44,
        child: Icon(icon, size: 19, color: _chatGreen),
      ),
    ),
  );
}

class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({
    required this.name,
    required this.photo,
    required this.preview,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  final String name;
  final String? photo;
  final String preview;
  final String time;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _chatBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8F4EF),
              backgroundImage: (photo != null && photo!.isNotEmpty)
                  ? NetworkImage(photo!)
                  : null,
              child: (photo == null || photo!.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0] : 'U',
                      style: const TextStyle(
                        color: _chatGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _chatText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _chatMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(color: _chatMuted, fontSize: 11),
                  ),
                const SizedBox(height: 8),
                unread > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _chatGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9BA6A0),
                      ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    color: _chatBg,
    padding: const EdgeInsets.all(24),
    alignment: Alignment.center,
    child: Container(
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
