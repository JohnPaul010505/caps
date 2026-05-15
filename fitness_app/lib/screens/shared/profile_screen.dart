import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.text),
        title: const Text('Profile',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 12),
            AppAvatar(
              name: auth.user?.email?.split('@').first ?? 'User',
              size: 72,
            ),
            const SizedBox(height: 14),
            Text(
              auth.user?.email ?? '—',
              style: const TextStyle(
                color: AppColors.text, fontSize: 16,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withOpacity(0.3)),
              ),
              child: Text(
                (auth.role ?? 'user').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.purpleLight, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 28),

            FitCard(child: Column(children: [
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: auth.user?.email ?? '—'),
              const Divider(color: AppColors.cardBorder, height: 1),
              _InfoTile(
                icon: Icons.verified_user_outlined,
                label: 'Role',
                value: auth.role ?? '—'),
              const Divider(color: AppColors.cardBorder, height: 1),
              _InfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Member since',
                value: auth.user?.createdAt != null
                    ? _fmtDate(DateTime.parse(auth.user!.createdAt))
                    : '—'),
            ])),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red.withOpacity(0.15),
                foregroundColor: AppColors.red,
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: AppColors.red.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(children: [
      Icon(icon, color: AppColors.subtext, size: 18),
      const SizedBox(width: 12),
      Text(label,
        style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
      const Spacer(),
      Text(value,
        style: const TextStyle(
          color: AppColors.text, fontSize: 13,
          fontWeight: FontWeight.w500)),
    ]),
  );
}
