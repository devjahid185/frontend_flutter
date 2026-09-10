import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'chat_screen.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(child: Text(_error!))
          : _threads.isEmpty
          ? const Center(child: Text('কোনো কথোপকথন নেই'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: _threads.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: _InboxHeader(title: 'মেসেজ ইনবক্স'),
                    );
                  }
                  final item = _threads[index - 1];
                  final name = (item['name'] ?? 'ব্যবহারকারী').toString();
                  final photo = item['photo_url']?.toString();
                  final last = item['last_message'] as Map<String, dynamic>?;
                  final time = _formatTime(last?['created_at']?.toString());
                  final unread = (item['unread_count'] as num?)?.toInt() ?? 0;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffe5e7eb)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xffe6f1ee),
                            backgroundImage: (photo != null && photo.isNotEmpty)
                                ? NetworkImage(photo)
                                : null,
                            child: (photo == null || photo.isEmpty)
                                ? Text(
                                    name.isNotEmpty ? name[0] : 'U',
                                    style: TextStyle(
                                      color: const Color(0xff006a4e),
                                      fontWeight: FontWeight.bold,
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
                                  style: TextStyle(
                                    color: const Color(0xff1f2937),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _preview(last),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xff4b5563),
                                  ),
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xff9ca3af),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff006a4e),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: TextStyle(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({required this.title});

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
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff1f2937),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
