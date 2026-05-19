import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'trainer_member_progress_screen.dart';
import 'trainer_member_chat_screen.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

/// Trainer profile for the currently logged-in trainer user.
final trainerProfileProvider = FutureProvider<Trainer?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return null;
  try {
    final res = await Supabase.instance.client
        .from('trainers')
        .select()
        .eq('user_id', auth.user!.id)
        .maybeSingle();
    return res != null ? Trainer.fromMap(res) : null;
  } catch (_) {
    return null;
  }
});

/// Real-time stream of all active members assigned to this trainer.
/// Updates automatically when the admin assigns or removes members.
final assignedMembersStreamProvider =
StreamProvider<List<Member>>((ref) async* {
  final trainer = await ref.watch(trainerProfileProvider.future);
  if (trainer == null) {
    yield [];
    return;
  }

  yield* Supabase.instance.client
      .from('members')
      .stream(primaryKey: ['id'])
      .eq('trainer_id', trainer.id)
      .map((rows) => (rows as List)
      .map((r) => Member.fromMap(r as Map<String, dynamic>))
      .where((m) => m.membershipStatus == 'active')
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName)));
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class TrainerHomeScreen extends ConsumerStatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  ConsumerState<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends ConsumerState<TrainerHomeScreen> {
  int _tab = 0;

  static const _tabTitles = ['Dashboard', 'Progress', 'Messages', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final trainerAsync  = ref.watch(trainerProfileProvider);
    final auth          = ref.watch(authProvider);
    final membersAsync  = ref.watch(assignedMembersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tabTitles[_tab],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            trainerAsync.when(
              data: (t) => Text(
                  t?.fullName ??
                      auth.user?.email?.split('@').first ??
                      'Trainer',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.subtext)),
              loading: () => const Text('Loading…',
                  style: TextStyle(fontSize: 12, color: AppColors.subtext)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: membersAsync.when(
        loading: () => const FullScreenLoader(),
        error: (e, __) => _ErrorRetry(
            message: 'Could not load members.',
            onRetry: () =>
                ref.invalidate(assignedMembersStreamProvider)),
        data: (members) => IndexedStack(
          index: _tab,
          children: [
            _DashboardTab(members: members),
            _ProgressTab(members: members),
            _MessagesTab(members: members),
            const _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF13131E),
      border:
      Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
    ),
    child: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      backgroundColor: Colors.transparent,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.purpleLight,
      unselectedItemColor: AppColors.subtext,
      selectedLabelStyle:
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

// ─── Shared: Error / Retry ────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(message,
          style: const TextStyle(color: AppColors.subtext, fontSize: 14)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Retry'),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — DASHBOARD
// Real-time member list; updates automatically when admin assigns members.
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final List<Member> members;
  const _DashboardTab({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('👥', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('No members assigned yet',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Ask your admin to assign members to you',
              style: TextStyle(color: AppColors.subtext, fontSize: 13)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {}, // Stream auto-refreshes
      color: AppColors.purple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary pills ─────────────────────────────────────────
          Row(children: [
            _StatPill(
                label: 'Members',
                value: '${members.length}',
                color: AppColors.purple),
            const SizedBox(width: 10),
            _StatPill(
                label: 'Can Chat',
                value:
                '${members.where((m) => m.userId != null).length}',
                color: AppColors.green),
            const SizedBox(width: 10),
            _StatPill(
                label: 'Exp. Soon',
                value:
                '${members.where((m) => m.isExpiringSoon).length}',
                color: AppColors.amber),
          ]),
          const SizedBox(height: 20),

          SectionHeader(
              title: 'Your Members',
              action: '${members.length} active',
              onAction: null),
          const SizedBox(height: 14),

          ...members.map((m) => _MemberDashTile(
            member: m,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      TrainerMemberProgressScreen(member: m)),
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PROGRESS
// Lists all members; tap any to view their full progress.
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  final List<Member> members;
  const _ProgressTab({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📊', style: TextStyle(fontSize: 52)),
          SizedBox(height: 16),
          Text('No members to monitor yet',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline,
                color: AppColors.purpleLight, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Tap any member to view their workouts, meals, and progress charts.',
                  style: TextStyle(
                      color: AppColors.subtext, fontSize: 12)),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        ...members.map((m) => _ProgressMemberTile(
          member: m,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    TrainerMemberProgressScreen(member: m)),
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — MESSAGES
// Lists members who have app accounts; tap to open 1-on-1 chat.
// ─────────────────────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  final List<Member> members;
  const _MessagesTab({required this.members});

  @override
  Widget build(BuildContext context) {
    final chatMembers = members.where((m) => m.userId != null).toList();

    if (chatMembers.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💬', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('No chats yet',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            members.isEmpty
                ? 'You have no members assigned.'
                : 'Your members need app accounts to chat.',
            style: const TextStyle(color: AppColors.subtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
            title: 'Conversations',
            action: '${chatMembers.length} members'),
        const SizedBox(height: 14),
        ...chatMembers.map((m) => _ChatMemberTile(
          member: m,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    TrainerMemberChatScreen(member: m)),
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TILE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Dashboard member tile ─────────────────────────────────────────────────────

class _MemberDashTile extends StatelessWidget {
  final Member       member;
  final VoidCallback onTap;
  const _MemberDashTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: FitCard(
      child: Row(children: [
        AppAvatar(name: member.fullName, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(member.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  if (member.userId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Text('💬',
                          style: TextStyle(fontSize: 9)),
                    ),
                  if (member.isExpiringSoon) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Text('⚠️ Exp.',
                          style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(
                  [
                    if (member.age != null) '${member.age} yrs',
                    member.goal ?? 'No goal set',
                  ].join('  •  '),
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (member.membershipType != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: Text(member.membershipType!,
                  style: const TextStyle(
                      color: AppColors.purpleLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 4),
          const Icon(Icons.chevron_right,
              color: AppColors.subtext, size: 18),
        ]),
      ]),
    ),
  );
}

// ── Progress member tile ──────────────────────────────────────────────────────

class _ProgressMemberTile extends StatelessWidget {
  final Member       member;
  final VoidCallback onTap;
  const _ProgressMemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: FitCard(
      child: Row(children: [
        AppAvatar(name: member.fullName, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  member.goal ?? 'No goal set',
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.weight != null || member.height != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (member.weight != null)
                          '${member.weight!.toStringAsFixed(0)} kg',
                        if (member.height != null)
                          '${member.height!.toStringAsFixed(0)} cm',
                      ].join('  ·  '),
                      style: const TextStyle(
                          color: AppColors.purpleLight, fontSize: 11),
                    ),
                  ),
              ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.25)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart,
                color: AppColors.purpleLight, size: 14),
            SizedBox(width: 4),
            Text('View',
                style: TextStyle(
                    color: AppColors.purpleLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    ),
  );
}

// ── Chat member tile ──────────────────────────────────────────────────────────

class _ChatMemberTile extends StatelessWidget {
  final Member       member;
  final VoidCallback onTap;
  const _ChatMemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: FitCard(
      child: Row(children: [
        Stack(children: [
          AppAvatar(name: member.fullName, size: 50),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.card, width: 2),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                const Text('Tap to open conversation',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 12)),
              ]),
        ),
        const Icon(Icons.chevron_right,
            color: AppColors.subtext, size: 20),
      ]),
    ),
  );
}

// ─── Stat Pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 11)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — PROFILE
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth          = ref.watch(authProvider);
    final trainerAsync  = ref.watch(trainerProfileProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          // ── Avatar + name ─────────────────────────────────────────
          trainerAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.purple)),
            error: (_, __) => const SizedBox.shrink(),
            data: (trainer) {
              final displayName = trainer?.fullName ??
                  auth.user?.email?.split('@').first ??
                  'Trainer';
              return Column(children: [
                // Avatar
                Stack(alignment: Alignment.bottomRight, children: [
                  AppAvatar(name: displayName, size: 80),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.purple, AppColors.purpleLight]),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.background, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.fitness_center,
                        color: Colors.white, size: 12),
                  ),
                ]),
                const SizedBox(height: 14),

                // Name
                Text(displayName,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.purpleLight]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('TRAINER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                ),

                // Specialty chip
                if (trainer?.specialty != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('⚡',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(trainer!.specialty!,
                          style: const TextStyle(
                              color: AppColors.subtextMid,
                              fontSize: 12)),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Account info card ────────────────────────────────
                FitCard(
                  child: Column(children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: auth.user?.email ?? '—',
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Role',
                      value: 'Trainer',
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member since',
                      value: auth.user?.createdAt != null
                          ? _fmtDate(DateTime.parse(auth.user!.createdAt))
                          : '—',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Trainer details card ─────────────────────────────
                if (trainer != null) ...[
                  FitCard(
                    child: Column(children: [
                      if (trainer.specialty != null) ...[
                        _InfoRow(
                          icon: Icons.star_outline,
                          label: 'Specialty',
                          value: trainer.specialty!,
                        ),
                        const Divider(color: AppColors.cardBorder, height: 1),
                      ],
                      _InfoRow(
                        icon: Icons.event_available_outlined,
                        label: 'Available',
                        value: trainer.availableDays.isEmpty
                            ? 'Not set'
                            : trainer.availableDays.join(', '),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Sign out button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Sign Out',
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700)),
                          content: const Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(color: AppColors.subtext)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      color: AppColors.subtext)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sign Out',
                                  style: TextStyle(color: AppColors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(authProvider.notifier).signOut();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red.withValues(alpha: 0.12),
                      foregroundColor: AppColors.red,
                      minimumSize: const Size(double.infinity, 52),
                      elevation: 0,
                      side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

// ─── Info row (profile) ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(children: [
      Icon(icon, color: AppColors.subtext, size: 18),
      const SizedBox(width: 12),
      Text(label,
          style: const TextStyle(
              color: AppColors.subtext, fontSize: 13)),
      const Spacer(),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}