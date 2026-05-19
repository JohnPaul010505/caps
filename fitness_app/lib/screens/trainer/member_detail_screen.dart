import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final memberDetailProvider =
FutureProvider.family<Member?, String>((ref, memberId) async {
  final res = await Supabase.instance.client
      .from('members')
      .select()
      .eq('id', memberId)
      .single();
  return Member.fromMap(res);
});

final memberWorkoutsThisWeekProvider =
FutureProvider.family<List<WorkoutLog>, String>((ref, memberId) async {
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final res = await Supabase.instance.client
      .from('workout_logs')
      .select()
      .eq('member_id', memberId)
      .gte('date', weekAgo.toIso8601String().split('T')[0]);
  return (res as List).map((r) => WorkoutLog.fromMap(r)).toList();
});

final chatMessagesProvider =
StreamProvider.family<List<ChatMessage>, _ChatArgs>((ref, args) {
  return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('timestamp')
      .map((list) => list
      .map((m) => ChatMessage.fromMap(m))
      .where((m) =>
  (m.senderId == args.myId && m.receiverId == args.otherId) ||
      (m.senderId == args.otherId && m.receiverId == args.myId))
      .toList());
});

class _ChatArgs {
  final String myId;
  final String otherId;
  const _ChatArgs(this.myId, this.otherId);

  @override
  bool operator ==(Object other) =>
      other is _ChatArgs && myId == other.myId && otherId == other.otherId;
  @override
  int get hashCode => Object.hash(myId, otherId);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _chatCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String myUserId, String memberUserId) async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _chatCtrl.clear();
    await Supabase.instance.client.from('messages').insert({
      'sender_id':   myUserId,
      'receiver_id': memberUserId,
      'message':     text,
      'timestamp':   DateTime.now().toIso8601String(),
    });
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync   = ref.watch(memberDetailProvider(widget.memberId));
    final workoutsAsync = ref.watch(memberWorkoutsThisWeekProvider(widget.memberId));
    final myUser        = ref.watch(authProvider).user;

    return memberAsync.when(
      loading: () => const FullScreenLoader(),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Member')),
        body: const Center(child: Text('Could not load member.',
            style: TextStyle(color: AppColors.subtext))),
      ),
      data: (member) {
        if (member == null) return const FullScreenLoader();
        final chatArgs = myUser != null && member.userId != null
            ? _ChatArgs(myUser.id, member.userId!)
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const BackButton(color: AppColors.text),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member.fullName,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Text(
                  '${member.gender ?? '—'} · ${member.age ?? '—'} yrs'
                      '${member.weight != null ? ' · ${member.weight!.toInt()} lbs' : ''}',
                  style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
            ]),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.purpleLight,
              unselectedLabelColor: AppColors.subtext,
              indicatorColor: AppColors.purpleLight,
              tabs: const [
                Tab(text: 'Progress'),
                Tab(text: 'Chat'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              // ── Progress Tab ──────────────────────────────────────
              _ProgressTab(member: member, workoutsAsync: workoutsAsync),

              // ── Chat Tab ──────────────────────────────────────────
              if (chatArgs != null)
                _ChatTab(
                  args: chatArgs,
                  myId: myUser!.id,
                  memberName: member.fullName,
                  onSend: () => _send(myUser.id, member.userId!),
                  controller: _chatCtrl,
                  sending: _sending,
                )
              else
                const Center(child: Text(
                    'Chat unavailable — member has no linked account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtext))),
            ],
          ),
        );
      },
    );
  }
}

// ─── Progress Tab ────────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  final Member member;
  final AsyncValue<List<WorkoutLog>> workoutsAsync;

  const _ProgressTab({required this.member, required this.workoutsAsync});

  @override
  Widget build(BuildContext context) {
    final workouts      = workoutsAsync.value ?? [];
    final workoutsDone  = workouts.length;
    final totalCals     = workouts.fold(0, (s, w) => s + (w.caloriesBurned ?? 0));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("This week's progress",
            style: TextStyle(color: AppColors.text, fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),

        FitCard(
          child: Column(children: [
            _ProgressRow(
              label: 'Workouts completed',
              subtitle: '$workoutsDone / 5 sessions',
              value: (workoutsDone / 5).clamp(0.0, 1.0),
              color: AppColors.purple,
            ),
            const SizedBox(height: 16),
            _ProgressRow(
              label: 'Calorie goal',
              subtitle: '${totalCals.toStringAsFixed(0)} / 2000 kcal',
              value: (totalCals / 2000).clamp(0, 1).toDouble(),
              color: AppColors.green,
            ),
            const SizedBox(height: 16),
            const _ProgressRow(
              label: 'Water intake',
              subtitle: '1.2L / 2.5L',
              value: 0.48,
              color: AppColors.amber,
            ),
          ]),
        ),

        const SizedBox(height: 20),
        const Text('Member Info',
            style: TextStyle(color: AppColors.text, fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        FitCard(
          child: Column(children: [
            _InfoRow('Goal',       member.goal ?? '—'),
            _InfoRow('Membership', member.membershipType ?? '—'),
            _InfoRow('Expires',    member.expirationDate ?? '—'),
            _InfoRow('Height',     member.height != null ? '${member.height} cm' : '—'),
            _InfoRow('Weight',     member.weight != null ? '${member.weight} kg' : '—'),
            _InfoRow('Contact',    member.contactNumber ?? '—'),
          ]),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final double value;
  final Color  color;

  const _ProgressRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.text, fontSize: 13,
                fontWeight: FontWeight.w500)),
        Text(subtitle,
            style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      GradientProgressBar(value: value, color: color, height: 7),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppColors.text, fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ─── Chat Tab ────────────────────────────────────────────────────────────────
//
// Uses ListView(reverse: true) so newest messages always sit at the bottom,
// exactly like Messenger — no manual scroll-to-bottom needed.
//

class _ChatTab extends ConsumerStatefulWidget {
  final _ChatArgs            args;
  final String               myId;
  final String               memberName;
  final VoidCallback         onSend;
  final TextEditingController controller;
  final bool                 sending;

  const _ChatTab({
    required this.args,
    required this.myId,
    required this.memberName,
    required this.onSend,
    required this.controller,
    required this.sending,
  });

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  int? _tappedIdx;

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(chatMessagesProvider(widget.args));

    return Column(children: [
      // ── Message list ──────────────────────────────────────────────
      Expanded(
        child: msgs.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.purple)),
          error: (_, __) => const Center(child: Text('Could not load chat.',
              style: TextStyle(color: AppColors.subtext))),
          data: (messages) {
            if (messages.isEmpty) {
              return const Center(child: Text(
                  'No messages yet.\nSend a recommendation!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.subtext)));
            }

            // Reverse the list so index 0 = newest → rendered at bottom
            final reversed = messages.reversed.toList();

            return GestureDetector(
              onTap: () => setState(() => _tappedIdx = null),
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: reversed.length,
                itemBuilder: (_, i) {
                  final m    = reversed[i];
                  final isMe = m.senderId == widget.myId;
                  final showTs = _tappedIdx == i;

                  return GestureDetector(
                    onTap: () => setState(
                            () => _tappedIdx = _tappedIdx == i ? null : i),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Show member avatar on their messages
                        if (!isMe)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: AppAvatar(name: widget.memberName, size: 24),
                          ),
                        _Bubble(
                            message: m.message,
                            isMe: isMe,
                            time: _fmt(m.timestamp)),
                        if (showTs)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 4, bottom: 4, left: 4, right: 4),
                            child: Text(_fmt(m.timestamp),
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

      // ── Input row ─────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Color(0xFF13131E),
          border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: AppColors.text, fontSize: 13),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Send recommendation…',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                fillColor: AppColors.card,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.sending ? null : widget.onSend,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.purpleLight]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppColors.purple.withOpacity(0.35),
                    blurRadius: 10)],
              ),
              alignment: Alignment.center,
              child: widget.sending
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String message;
  final bool   isMe;
  final String time;

  const _Bubble({
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4, top: 6),
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
                  fontSize: 13.5)),
        ),
        Text(time,
            style: const TextStyle(color: AppColors.subtext, fontSize: 10)),
      ],
    ),
  );
}