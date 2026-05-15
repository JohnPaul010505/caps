import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

/// Fetches the trainer row for the currently logged-in user
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

/// Fetches all active members assigned to this trainer
final assignedMembersProvider = FutureProvider<List<Member>>((ref) async {
  final trainer = await ref.watch(trainerProfileProvider.future);
  if (trainer == null) return [];
  try {
    final res = await Supabase.instance.client
        .from('members')
        .select()
        .eq('trainer_id', trainer.id)
        .eq('membership_status', 'active')
        .order('full_name');
    return (res as List).map((m) => Member.fromMap(m)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class TrainerHomeScreen extends ConsumerWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(assignedMembersProvider);
    final trainerAsync = ref.watch(trainerProfileProvider);
    final auth         = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FitTrack',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            trainerAsync.when(
              data: (t) => Text(
                t?.fullName ?? auth.user?.email?.split('@').first ?? 'Trainer',
                style: const TextStyle(fontSize: 12, color: AppColors.subtext),
              ),
              loading: () => const Text('Loading…',
                  style: TextStyle(fontSize: 12, color: AppColors.subtext)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline, color: AppColors.text),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const FullScreenLoader(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load members.',
                  style: TextStyle(color: AppColors.subtext)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(assignedMembersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (members) => members.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('No members assigned yet',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Ask the admin to assign members to you',
                  style:
                  TextStyle(color: AppColors.subtext, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(assignedMembersProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () async => ref.refresh(assignedMembersProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Stats row ───────────────────────────────────
              Row(children: [
                _StatPill(
                    label: 'Members',
                    value: '${members.length}',
                    color: AppColors.purple),
                const SizedBox(width: 10),
                _StatPill(
                    label: 'With App',
                    value:
                    '${members.where((m) => m.userId != null).length}',
                    color: AppColors.green),
              ]),
              const SizedBox(height: 20),

              const SectionHeader(title: 'Your Members'),
              const SizedBox(height: 14),

              ...members.map((m) => _MemberTile(member: m)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FitBottomNav(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Members'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
        onTap: (i) {
          if (i == 1) context.push('/profile');
        },
      ),
    );
  }
}

// ─── Stat Pill ───────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: AppColors.subtext, fontSize: 12)),
    ]),
  );
}

// ─── Member Tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final Member member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/trainer/member/${member.id}'),
    child: FitCard(
      child: Row(children: [
        AppAvatar(name: member.fullName, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(member.fullName,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                // Show if they have app account (can chat)
                if (member.userId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Text('💬 Chat',
                        style: TextStyle(
                            color: AppColors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('${member.age ?? "—"} yrs',
                    style: const TextStyle(
                        color: AppColors.subtext, fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                        color: AppColors.subtext,
                        shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      member.goal ?? 'No goal set',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 12)),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Membership badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (member.membershipType != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
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
          ],
        ),
      ]),
    ),
  );
}