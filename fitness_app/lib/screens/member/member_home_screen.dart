import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

// ─── Provider to fetch member profile ──────────────────────────────────────

final memberProfileProvider = FutureProvider<Member?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return null;

  try {
    final res = await Supabase.instance.client
        .from('members')
        .select()
        .eq('user_id', auth.user!.id)
        .maybeSingle();
    return res != null ? Member.fromMap(res) : null;
  } catch (_) {
    return null;
  }
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProfileProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: memberAsync.when(
        loading: () => const FullScreenLoader(),
        error: (_, __) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Error'),
            actions: [
              IconButton(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: const Center(child: Text('Could not load profile.')),
        ),
        data: (member) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FitTrack',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(member?.fullName ?? 'Member',
                      style: const TextStyle(fontSize: 12, color: AppColors.subtext)),
                ]),
            actions: [
              IconButton(
                onPressed: () => context.push('/member/profile'),
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Membership Status ────────────────────────────────────
              if (member != null) ...[
                FitCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.membershipType ?? 'Standard',
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              member.isExpiringSoon
                                  ? 'Expires soon'
                                  : 'Valid until ${member.expirationDate ?? '—'}',
                              style: const TextStyle(
                                  color: AppColors.subtext, fontSize: 12)),
                        ],
                      ),
                      StatusBadge(
                          status: member.isExpiringSoon
                              ? 'Exp. Soon'
                              : member.membershipStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Quick Action Grid ────────────────────────────────────
              const Text('Quick actions',
                  style: TextStyle(
                      color: AppColors.text, fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _QuickActionCard(
                    emoji: '🏋️',
                    label: 'Log Workout',
                    onTap: () => context.push('/member/log-workout'),
                  ),
                  _QuickActionCard(
                    emoji: '🍽️',
                    label: 'Log Meal',
                    onTap: () => context.push('/member/log-meal'),
                  ),
                  _QuickActionCard(
                    emoji: '📊',
                    label: 'My Progress',
                    onTap: () => context.push('/member/progress'),
                  ),
                  _QuickActionCard(
                    emoji: '💬',
                    label: 'Chat with Trainer',
                    onTap: () => context.push('/member/chat'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Stats ────────────────────────────────────────────────
              if (member != null) ...[
                const Text('Your stats',
                    style: TextStyle(
                        color: AppColors.text, fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatMiniCard(
                      emoji: '⚖️',
                      value: member.weight?.toStringAsFixed(0) ?? '—',
                      label: 'kg',
                      accentColor: AppColors.purple,
                    ),
                    const SizedBox(width: 10),
                    StatMiniCard(
                      emoji: '📏',
                      value: member.height?.toStringAsFixed(0) ?? '—',
                      label: 'cm',
                      accentColor: AppColors.blue,
                    ),
                    const SizedBox(width: 10),
                    StatMiniCard(
                      emoji: '🎯',
                      value: member.goal?.split(' ')[0] ?? '—',
                      label: 'Goal',
                      accentColor: AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ── Trainer Info ────────────────────────────────────────
              if (member != null && member.trainerId != null) ...[
                const Text('Your trainer',
                    style: TextStyle(
                        color: AppColors.text, fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                FutureBuilder<dynamic>(
                  future: Supabase.instance.client
                      .from('trainers')
                      .select()
                      .eq('id', member.trainerId!)
                      .maybeSingle(),
                  builder: (context, snap) {
                    final trainer = snap.data != null
                        ? Trainer.fromMap(snap.data!)
                        : null;
                    return trainer != null
                        ? FitCard(
                      child: Row(children: [
                        AppAvatar(name: trainer.fullName, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trainer.fullName,
                                  style: const TextStyle(
                                      color: AppColors.text, fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              if (trainer.specialty != null)
                                Text(trainer.specialty!,
                                    style: const TextStyle(
                                        color: AppColors.subtext,
                                        fontSize: 12)),
                            ],
                          ),
                        ),
                      ]),
                    )
                        : const SizedBox.shrink();
                  },
                ),
              ] else if (member != null && member.wantsTrainer) ...[
                FitCard(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                          'A trainer will be assigned soon',
                          style: TextStyle(
                              color: AppColors.subtext, fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: FitBottomNav(
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.trending_up_outlined),
                  activeIcon: Icon(Icons.trending_up),
                  label: 'Progress'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat_outlined),
                  activeIcon: Icon(Icons.chat),
                  label: 'Chat'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
            onTap: (i) {
              switch (i) {
                case 0:
                  break; // Already home
                case 1:
                  context.push('/member/progress');
                case 2:
                  context.push('/member/chat');
                case 3:
                  context.push('/member/profile');
              }
            },
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.text, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}