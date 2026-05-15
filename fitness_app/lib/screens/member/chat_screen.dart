import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'member_home_screen.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final _chatStreamProvider =
    StreamProvider.family<List<ChatMessage>, _Pair>((ref, pair) {
  return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('timestamp')
      .map((list) => list
          .map((m) => ChatMessage.fromMap(m))
          .where((m) =>
              (m.senderId == pair.a && m.receiverId == pair.b) ||
              (m.senderId == pair.b && m.receiverId == pair.a))
          .toList());
});

class _Pair {
  final String a, b;
  const _Pair(this.a, this.b);
  @override bool operator ==(Object o) => o is _Pair && a == o.a && b == o.b;
  @override int get hashCode => Object.hash(a, b);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl      = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String myId, String trainerId) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _ctrl.clear();
    await Supabase.instance.client.from('messages').insert({
      'sender_id':   myId,
      'receiver_id': trainerId,
      'message':     text,
      'timestamp':   DateTime.now().toIso8601String(),
    });
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(memberProfileProvider);
    final myUser      = ref.watch(authProvider).user;

    return memberAsync.when(
      loading: () => const FullScreenLoader(),
      error: (_, __) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error'))),
      data: (member) {
        if (member == null || member.trainerId == null || myUser == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: const BackButton(color: AppColors.text),
              title: const Text('Chat')),
            body: const Center(
              child: Text('No trainer assigned yet.',
                style: TextStyle(color: AppColors.subtext))),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('trainers')
              .select()
              .eq('id', member.trainerId!)
              .maybeSingle(),
          builder: (context, snap) {
            final trainerName = snap.data?['full_name'] as String? ?? 'Trainer';
            final trainerUserId = snap.data?['user_id'] as String? ?? member.trainerId!;
            final pair = _Pair(myUser.id, trainerUserId);
            final msgs = ref.watch(_chatStreamProvider(pair));

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                leading: const BackButton(color: AppColors.text),
                title: Row(children: [
                  AppAvatar(name: trainerName, size: 34),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trainerName,
                      style: const TextStyle(
                        color: AppColors.text, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                    const Text('Your Trainer',
                      style: TextStyle(
                        color: AppColors.subtext, fontSize: 11)),
                  ]),
                ]),
              ),
              body: Column(children: [
                Expanded(
                  child: msgs.when(
                    loading: () => const Center(child: CircularProgressIndicator(
                      color: AppColors.purple)),
                    error: (_, __) => const Center(
                      child: Text('Could not load messages.',
                        style: TextStyle(color: AppColors.subtext))),
                    data: (messages) {
                      if (messages.isNotEmpty) _scrollToBottom();
                      return messages.isEmpty
                        ? const Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('👋', style: TextStyle(fontSize: 36)),
                              SizedBox(height: 12),
                              Text('Start a conversation with your trainer!',
                                style: TextStyle(color: AppColors.subtext,
                                  fontSize: 13)),
                            ]))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (_, i) {
                              final m = messages[i];
                              final isMe = m.senderId == myUser.id;
                              return _Bubble(
                                message: m.message,
                                isMe: isMe,
                                time: _fmt(m.timestamp),
                              );
                            },
                          );
                    },
                  ),
                ),

                // ── Input ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF13131E),
                    border: Border(top: BorderSide(
                      color: AppColors.cardBorder, width: 0.5)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(
                          color: AppColors.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Message your trainer…',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                          fillColor: AppColors.card,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(myUser.id, trainerUserId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sending
                          ? null
                          : () => _send(myUser.id, trainerUserId),
                      child: Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.purple, AppColors.purpleLight]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: AppColors.purple.withOpacity(0.35),
                            blurRadius: 10)],
                        ),
                        alignment: Alignment.center,
                        child: _sending
                          ? const SizedBox(width: 18, height: 18,
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
          },
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Bubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;

  const _Bubble({required this.message, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) => Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 3, top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: isMe ? AppColors.purple : AppColors.card,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(16),
              topRight:    const Radius.circular(16),
              bottomLeft:  Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Text(message,
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.text,
              fontSize: 14, height: 1.4)),
        ),
        Text(time,
          style: const TextStyle(color: AppColors.subtext, fontSize: 10)),
      ],
    ),
  );
}
