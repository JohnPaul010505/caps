import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

class _Pair {
  final String a, b;
  const _Pair(this.a, this.b);
  @override
  bool operator ==(Object o) => o is _Pair && a == o.a && b == o.b;
  @override
  int get hashCode => Object.hash(a, b);
}

final _trainerChatProvider =
StreamProvider.family<List<ChatMessage>, _Pair>((ref, pair) =>
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('timestamp')
        .map((list) => list
        .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
        .where((m) =>
    (m.senderId == pair.a && m.receiverId == pair.b) ||
        (m.senderId == pair.b && m.receiverId == pair.a))
        .toList()));

// ─── Screen ──────────────────────────────────────────────────────────────────

class TrainerMemberChatScreen extends ConsumerStatefulWidget {
  final Member member;
  const TrainerMemberChatScreen({super.key, required this.member});

  @override
  ConsumerState<TrainerMemberChatScreen> createState() =>
      _TrainerMemberChatScreenState();
}

class _TrainerMemberChatScreenState
    extends ConsumerState<TrainerMemberChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();
  bool _sending     = false;
  int? _tappedIdx;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll ──────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send text ───────────────────────────────────────────────────────────────

  Future<void> _sendText(String myUserId, String memberUserId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id':    myUserId,
        'receiver_id':  memberUserId,
        'message':      text,
        'timestamp':    DateTime.now().toIso8601String(),
        'message_type': 'text',
      });
    } catch (_) {}
    if (mounted) {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  // ── Send image ──────────────────────────────────────────────────────────────

  Future<void> _sendImage(String myUserId, String memberUserId) async {
    try {
      final xf = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 75);
      if (xf == null || !mounted) return;
      setState(() => _sending = true);

      final bytes    = await xf.readAsBytes();
      final ext      = xf.path.split('.').last.toLowerCase();
      final fileName = 'chat/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('uploads')
          .uploadBinary(fileName, bytes,
          fileOptions: FileOptions(
              contentType: 'image/$ext', upsert: false));
      final url = Supabase.instance.client.storage
          .from('uploads')
          .getPublicUrl(fileName);

      await Supabase.instance.client.from('messages').insert({
        'sender_id':    myUserId,
        'receiver_id':  memberUserId,
        'message':      '',
        'timestamp':    DateTime.now().toIso8601String(),
        'message_type': 'image',
        'image_url':    url,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppColors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  // ── Timestamp formatting ─────────────────────────────────────────────────────

  String _smartTimestamp(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dt.year, dt.month, dt.day);
    final tStr  = DateFormat('h:mm a').format(dt);
    if (day == today) return tStr;
    if (today.difference(day).inDays == 1) return 'Yesterday $tStr';
    return '${DateFormat('MMM d').format(dt)}, $tStr';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final myUser = ref.watch(authProvider).user;

    if (myUser == null || widget.member.userId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const BackButton(color: AppColors.text),
          title: Text(widget.member.fullName,
              style: const TextStyle(color: AppColors.text)),
        ),
        body: const Center(
          child: Text('This member does not have an app account yet.',
              style: TextStyle(color: AppColors.subtext)),
        ),
      );
    }

    final memberUserId = widget.member.userId!;
    final pair         = _Pair(myUser.id, memberUserId);
    final msgsAsync    = ref.watch(_trainerChatProvider(pair));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.text),
        title: Row(children: [
          Stack(children: [
            AppAvatar(name: widget.member.fullName, size: 36),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 11, height: 11,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.member.fullName,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              const Text('Member',
                  style: TextStyle(
                      color: AppColors.green, fontSize: 10)),
            ]),
          ]),
        ]),
      ),
      body: Column(children: [
        // ── Messages ──────────────────────────────────────────────
        Expanded(
          child: msgsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.purple)),
            error: (_, __) => const Center(
                child: Text('Could not load messages.',
                    style: TextStyle(color: AppColors.subtext))),
            data: (msgs) {
              if (msgs.isNotEmpty) _scrollToBottom();

              if (msgs.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AppAvatar(name: widget.member.fullName, size: 64),
                    const SizedBox(height: 14),
                    Text(widget.member.fullName,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Start the conversation!',
                        style: TextStyle(
                            color: AppColors.subtext, fontSize: 13)),
                  ]),
                );
              }

              final reversed = msgs.reversed.toList();
              return GestureDetector(
                onTap: () => setState(() => _tappedIdx = null),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: reversed.length,
                  itemBuilder: (_, i) {
                    final m    = reversed[i];
                    final isMe = m.senderId == myUser.id;
                    final showTs = _tappedIdx == i;
                    return GestureDetector(
                      onTap: () => setState(() =>
                      _tappedIdx = _tappedIdx == i ? null : i),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding:
                              const EdgeInsets.only(left: 4, bottom: 3),
                              child: AppAvatar(
                                  name: widget.member.fullName, size: 22),
                            ),
                          _Bubble(message: m, isMe: isMe),
                          if (showTs)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  4, 3, 4, 4),
                              child: Text(_smartTimestamp(m.timestamp),
                                  style: const TextStyle(
                                      color: AppColors.subtext,
                                      fontSize: 10.5)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              14, 10, 14,
              MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: const BoxDecoration(
            color: Color(0xFF13131E),
            border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
          ),
          child: Row(children: [
            // Image picker button
            GestureDetector(
              onTap: _sending
                  ? null
                  : () => _sendImage(myUser.id, memberUserId),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.subtext, size: 20),
              ),
            ),
            const SizedBox(width: 10),

            // Text input
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(
                    color: AppColors.text, fontSize: 14),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                  'Message ${widget.member.fullName.split(' ').first}…',
                  hintStyle: const TextStyle(
                      color: AppColors.subtext, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  fillColor: AppColors.card,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendText(myUser.id, memberUserId),
              ),
            ),
            const SizedBox(width: 10),

            // Send button
            GestureDetector(
              onTap: _sending
                  ? null
                  : () => _sendText(myUser.id, memberUserId),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.purple, AppColors.purpleLight]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.35),
                        blurRadius: 10)
                  ],
                ),
                alignment: Alignment.center,
                child: _sending
                    ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Chat bubble ─────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool        isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) => Align(
    alignment:
    isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 4, bottom: 2),
      constraints: BoxConstraints(
          maxWidth:
          MediaQuery.of(context).size.width * 0.72),
      padding: message.messageType == 'image'
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.messageType == 'image'
            ? Colors.transparent
            : (isMe ? AppColors.purple : AppColors.card),
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(16),
          topRight:    const Radius.circular(16),
          bottomLeft:  Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: message.messageType == 'image' &&
          message.imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
          progress == null
              ? child
              : const SizedBox(
              width: 180, height: 120,
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.purple))),
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.broken_image_outlined,
                color: AppColors.subtext, size: 32),
          ),
        ),
      )
          : Text(
        message.message,
        style: TextStyle(
            color:
            isMe ? Colors.white : AppColors.text,
            fontSize: 14,
            height: 1.4),
      ),
    ),
  );
}