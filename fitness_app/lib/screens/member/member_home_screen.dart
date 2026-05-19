import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'member_calendar_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutExercise {
  final String name;
  final int    sets;
  final int    reps;
  final double weightKg;

  const WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKOUT SESSION STATE + NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutSessionState {
  final List<WorkoutExercise> exercises;
  final bool isRunning;
  final bool isFinished;
  final int  elapsedSeconds;

  const WorkoutSessionState({
    this.exercises      = const [],
    this.isRunning      = false,
    this.isFinished     = false,
    this.elapsedSeconds = 0,
  });

  WorkoutSessionState copyWith({
    List<WorkoutExercise>? exercises,
    bool? isRunning,
    bool? isFinished,
    int?  elapsedSeconds,
  }) => WorkoutSessionState(
    exercises:      exercises      ?? this.exercises,
    isRunning:      isRunning      ?? this.isRunning,
    isFinished:     isFinished     ?? this.isFinished,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
  );

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets);
  int get calEst    => exercises.fold(0, (s, e) => s + (e.sets * e.reps * 5));

  String get timerLabel {
    final h = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  Timer? _timer;

  WorkoutSessionNotifier() : super(const WorkoutSessionState());

  void addExercise(WorkoutExercise ex) =>
      state = state.copyWith(exercises: [...state.exercises, ex]);

  void removeExercise(int index) {
    final list = [...state.exercises]..removeAt(index);
    state = state.copyWith(exercises: list);
  }

  void start() {
    if (state.isRunning || state.isFinished) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  Future<void> finish(String memberId) async {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isFinished: true);
    try {
      await Supabase.instance.client.from('workout_logs').insert({
        'member_id':       memberId,
        'workout_type':    state.exercises.isNotEmpty
            ? state.exercises.first.name
            : 'Custom Session',
        'duration':        state.elapsedSeconds ~/ 60,
        'calories_burned': state.calEst,
        'date':            DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    } catch (_) {}
  }

  void reset() {
    _timer?.cancel();
    state = const WorkoutSessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

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

/// Real-time weekly workout counts (Mon–Sun of current week).
/// Automatically resets each new week — no manual reset needed.
final weeklyWorkoutsProvider =
StreamProvider.family<Map<int, int>, String>((ref, memberId) {
  final now       = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);

  return Supabase.instance.client
      .from('workout_logs')
      .stream(primaryKey: ['id'])
      .eq('member_id', memberId)
      .map((rows) {
    final Map<int, int> map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (final row in rows) {
      final d = DateTime.tryParse(row['date'] as String? ?? '');
      if (d == null) continue;
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      if (dStr.compareTo(weekStartStr) >= 0) {
        map[d.weekday] = (map[d.weekday] ?? 0) + 1;
      }
    }
    return map;
  });
});

/// Real-time monthly workout counts (day-of-month → count).
final monthlyWorkoutsProvider =
StreamProvider.family<Map<int, int>, String>((ref, memberId) {
  final now        = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);

  return Supabase.instance.client
      .from('workout_logs')
      .stream(primaryKey: ['id'])
      .eq('member_id', memberId)
      .map((rows) {
    final Map<int, int> map = {};
    for (final row in rows) {
      final d = DateTime.tryParse(row['date'] as String? ?? '');
      if (d == null) continue;
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      if (dStr.compareTo(monthStartStr) >= 0) {
        map[d.day] = (map[d.day] ?? 0) + 1;
      }
    }
    return map;
  });
});

final todayMealsProvider =
FutureProvider.family<List<MealLog>, String>((ref, memberId) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  try {
    final res = await Supabase.instance.client
        .from('meal_logs')
        .select()
        .eq('member_id', memberId)
        .eq('date', today)
        .order('created_at', ascending: true);
    return (res as List).map((m) => MealLog.fromMap(m)).toList();
  } catch (_) {
    return [];
  }
});

final workoutSessionProvider =
StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>(
        (_) => WorkoutSessionNotifier());

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN — 5-tab IndexedStack
// ─────────────────────────────────────────────────────────────────────────────

class MemberHomeScreen extends ConsumerStatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  ConsumerState<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends ConsumerState<MemberHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(memberProfileProvider);
    return memberAsync.when(
      loading: () => const FullScreenLoader(),
      error:   (_, __) => _errorScaffold(),
      data:    (member) {
        if (member == null) return _noProfileScaffold();
        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _tab,
            children: [
              _HomeTab(member: member),
              _WorkoutTab(member: member),
              _FoodTab(member: member),
              _ProgressTab(member: member),
              _ChatTab(member: member),
            ],
          ),
          bottomNavigationBar: _nav(),
        );
      },
    );
  }

  Widget _nav() => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF13131E),
      border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
    ),
    child: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      backgroundColor: Colors.transparent,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.purpleLight,
      unselectedItemColor: AppColors.subtext,
      selectedLabelStyle:   const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Workout'),
        BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Food'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Progress'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Trainer'),
      ],
    ),
  );

  Widget _errorScaffold() => const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Error loading profile',
          style: TextStyle(color: AppColors.subtext))));

  Widget _noProfileScaffold() => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Profile not found',
            style: TextStyle(color: AppColors.text, fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Sign Out')),
      ])));
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — HOME
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final Member member;
  const _HomeTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyWorkoutsProvider(member.id));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [

          // ── Greeting ─────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Good day 👋',
                  style: TextStyle(color: AppColors.subtext, fontSize: 13)),
              Text(member.fullName,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
            // Tapping avatar opens profile sheet
            GestureDetector(
              onTap: () => _showProfileSheet(context, ref, member),
              child: Stack(children: [
                AppAvatar(name: member.fullName, size: 44),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, size: 9, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Membership card ───────────────────────────────────────
          FitCard(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(member.membershipType ?? 'Standard',
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    member.isExpiringSoon
                        ? 'Expires soon!'
                        : 'Valid until ${member.expirationDate ?? '—'}',
                    style: TextStyle(
                        color: member.isExpiringSoon ? AppColors.amber : AppColors.subtext,
                        fontSize: 12)),
              ]),
              StatusBadge(
                  status: member.isExpiringSoon ? 'Exp. Soon' : member.membershipStatus),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Weekly workout chart ──────────────────────────────────
          const _SectionLabel(label: 'This Week'),
          const SizedBox(height: 12),
          weeklyAsync.when(
            loading: () => const _LoadingCard(height: 160),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (data) => _WeeklyChartCard(weeklyData: data),
          ),
          const SizedBox(height: 20),

          // ── Stats row ─────────────────────────────────────────────
          Row(children: [
            StatMiniCard(
                emoji: '⚖️',
                value: member.weight?.toStringAsFixed(0) ?? '—',
                label: 'kg',
                accentColor: AppColors.purple),
            const SizedBox(width: 10),
            StatMiniCard(
                emoji: '📏',
                value: member.height?.toStringAsFixed(0) ?? '—',
                label: 'cm',
                accentColor: AppColors.blue),
            const SizedBox(width: 10),
            StatMiniCard(
                emoji: '🎯',
                value: member.goal?.split(' ').first ?? '—',
                label: 'Goal',
                accentColor: AppColors.green),
          ]),
          const SizedBox(height: 20),

          // ── Trainer card ──────────────────────────────────────────
          if (member.trainerId != null) ...[
            const _SectionLabel(label: 'Your Trainer'),
            const SizedBox(height: 12),
            _TrainerCard(trainerId: member.trainerId!),
          ],
        ],
      ),
    );
  }

  // ── Profile bottom sheet ──────────────────────────────────────────────────

  void _showProfileSheet(BuildContext ctx, WidgetRef ref, Member member) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MemberProfileSheet(member: member),
    );
  }
}

// ── Member Profile Sheet ──────────────────────────────────────────────────────

class _MemberProfileSheet extends ConsumerStatefulWidget {
  final Member member;
  const _MemberProfileSheet({required this.member});

  @override
  ConsumerState<_MemberProfileSheet> createState() => _MemberProfileSheetState();
}

class _MemberProfileSheetState extends ConsumerState<_MemberProfileSheet> {
  bool _editing = false;
  bool _saving  = false;

  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _contactCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl  = TextEditingController(
        text: widget.member.weight?.toStringAsFixed(0) ?? '');
    _heightCtrl  = TextEditingController(
        text: widget.member.height?.toStringAsFixed(0) ?? '');
    _goalCtrl    = TextEditingController(text: widget.member.goal ?? '');
    _contactCtrl = TextEditingController(
        text: widget.member.contactNumber ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _goalCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('members')
          .update({
        'weight':         double.tryParse(_weightCtrl.text),
        'height':         double.tryParse(_heightCtrl.text),
        'goal':           _goalCtrl.text.trim(),
        'contact_number': _contactCtrl.text.trim(),
      })
          .eq('id', widget.member.id);
      ref.invalidate(memberProfileProvider);
      if (mounted) {
        setState(() { _editing = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated!'),
                backgroundColor: AppColors.green));
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Avatar + name
        AppAvatar(name: widget.member.fullName, size: 64),
        const SizedBox(height: 12),
        Text(widget.member.fullName,
            style: const TextStyle(
                color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(auth.user?.email ?? '',
            style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
          ),
          child: const Text('MEMBER',
              style: TextStyle(
                  color: AppColors.purpleLight,
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 20),

        if (_editing) ...[
          // ── Edit form ─────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SheetLabel('WEIGHT (kg)'),
              const SizedBox(height: 6),
              TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(hintText: '70')),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SheetLabel('HEIGHT (cm)'),
              const SizedBox(height: 6),
              TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(hintText: '170')),
            ])),
          ]),
          const SizedBox(height: 12),
          _SheetLabel('FITNESS GOAL'),
          const SizedBox(height: 6),
          TextField(
              controller: _goalCtrl,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'e.g. Lose weight')),
          const SizedBox(height: 12),
          _SheetLabel('CONTACT NUMBER'),
          const SizedBox(height: 6),
          TextField(
              controller: _contactCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: '+63 9xx xxx xxxx')),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.subtext,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ]),
        ] else ...[
          // ── Action buttons ────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Update Profile',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign Out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red.withValues(alpha: 0.15),
                foregroundColor: AppColors.red,
                side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Weekly bar chart card ────────────────────────────────────────────────────

class _WeeklyChartCard extends StatelessWidget {
  final Map<int, int> weeklyData;
  const _WeeklyChartCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final today   = DateTime.now().weekday;
    final maxVal  = weeklyData.values.fold(0, max).toDouble();
    final chartMax = max(maxVal, 3.0);

    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final groups = List.generate(7, (i) {
      final wd      = i + 1;
      final count   = weeklyData[wd] ?? 0;
      final isToday = wd == today;
      final hasDone = count > 0;

      final rodColor = isToday && hasDone
          ? const Color(0xFF00E5A0)
          : hasDone
          ? AppColors.purple
          : Colors.transparent;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (hasDone || isToday)
                ? max(count.toDouble(), isToday ? 0.15 : 0)
                : 0,
            width: 22,
            color: rodColor,
            gradient: isToday && hasDone
                ? const LinearGradient(
                colors: [Color(0xFF00E5A0), Color(0xFF00C896)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)
                : hasDone
                ? LinearGradient(
                colors: [AppColors.purpleLight, AppColors.purple],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
        showingTooltipIndicators: hasDone ? [0] : [],
      );
    });

    return FitCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        SizedBox(
          height: 140,
          child: BarChart(BarChartData(
            barGroups: groups,
            maxY: chartMax + 1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (x, _) {
                  final wd      = x.toInt() + 1;
                  final isToday = wd == today;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(days[x.toInt()],
                        style: TextStyle(
                            color:      isToday ? const Color(0xFF00E5A0) : AppColors.subtext,
                            fontSize:   12,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                  );
                },
              )),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: const Color(0xFF1E1E3A),
                getTooltipItem: (_, __, rod, ___) => rod.toY < 0.2
                    ? null
                    : BarTooltipItem(rod.toY.toInt().toString(),
                    const TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          )),
        ),
        const SizedBox(height: 8),
        const Text(
            'Bar height = workouts per day  ·  🟢 today  ·  🟣 completed',
            style: TextStyle(color: AppColors.subtext, fontSize: 10.5)),
      ]),
    );
  }
}

// ─── Trainer card ─────────────────────────────────────────────────────────────

class _TrainerCard extends StatelessWidget {
  final String trainerId;
  const _TrainerCard({required this.trainerId});

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: Supabase.instance.client
        .from('trainers').select().eq('id', trainerId).maybeSingle(),
    builder: (_, snap) {
      final t = snap.data != null ? Trainer.fromMap(snap.data!) : null;
      if (t == null) return const SizedBox.shrink();
      return FitCard(child: Row(children: [
        AppAvatar(name: t.fullName, size: 48),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.fullName,
              style: const TextStyle(
                  color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
          if (t.specialty != null)
            Text(t.specialty!,
                style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
          ),
          child: const Text('Your Trainer',
              style: TextStyle(
                  color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]));
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — WORKOUT
// ─────────────────────────────────────────────────────────────────────────────

class _WorkoutTab extends ConsumerWidget {
  final Member member;
  const _WorkoutTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutSessionProvider);

    if (session.isFinished) {
      return _WorkoutSummaryView(
        session: session,
        onReset: () => ref.read(workoutSessionProvider.notifier).reset(),
      );
    }

    return SafeArea(
      child: Column(children: [
        // ── Header ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            const Expanded(
                child: Text('WORKOUT LOG',
                    style: TextStyle(
                        color: AppColors.text, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: 0.5))),
            _StatusPill(
                label: session.isRunning ? 'Live' : 'Ready',
                color: session.isRunning ? AppColors.green : AppColors.subtext,
                dot: true),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Timer card ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A1040), Color(0xFF0D1A2E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              const Text('SESSION DURATION',
                  style: TextStyle(
                      color: AppColors.subtext, fontSize: 11,
                      letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(session.timerLabel,
                  style: TextStyle(
                      color: session.isRunning
                          ? const Color(0xFF00E5A0)
                          : AppColors.text,
                      fontSize: 48, fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Start / Stop button ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (session.isRunning) {
                  ref.read(workoutSessionProvider.notifier).finish(member.id);
                } else {
                  ref.read(workoutSessionProvider.notifier).start();
                }
              },
              icon: Icon(
                  session.isRunning
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                  size: 22),
              label: Text(session.isRunning ? 'Stop & Finish' : 'Start Workout',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                session.isRunning ? const Color(0xFFDC2626) : const Color(0xFF00C896),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                shadowColor:
                (session.isRunning ? Colors.red : const Color(0xFF00C896))
                    .withValues(alpha: 0.4),
                elevation: 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Exercise list header ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text("TODAY'S EXERCISES",
                style: TextStyle(
                    color: AppColors.subtext, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const Spacer(),
            Text('${session.exercises.length} added',
                style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Exercise list ──────────────────────────────────────────
        Expanded(
          child: session.exercises.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏋️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('No exercises yet',
                style: TextStyle(color: AppColors.subtext, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Tap + Add Exercise below',
                style: TextStyle(
                    color: AppColors.subtext.withValues(alpha: 0.6), fontSize: 12)),
          ]))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: session.exercises.length,
            itemBuilder: (_, i) => _ExerciseCard(
              exercise: session.exercises[i],
              onDelete: () =>
                  ref.read(workoutSessionProvider.notifier).removeExercise(i),
            ),
          ),
        ),

        // ── Add exercise button ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _showAddExercise(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Exercise',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purpleLight,
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showAddExercise(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddExerciseSheet(
          onAdd: (ex) => ref.read(workoutSessionProvider.notifier).addExercise(ex)),
    );
  }
}

// ── Workout summary (after finishing) ─────────────────────────────────────────

class _WorkoutSummaryView extends StatelessWidget {
  final WorkoutSessionState session;
  final VoidCallback         onReset;
  const _WorkoutSummaryView({required this.session, required this.onReset});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Workout Complete! 🎉',
            style: TextStyle(
                color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Great session — your workout has been saved.',
            style: TextStyle(color: AppColors.subtext, fontSize: 13)),
        const SizedBox(height: 24),
        Row(children: [
          _SummaryStatBox(label: 'Duration',   value: session.timerLabel,              color: AppColors.purple),
          const SizedBox(width: 12),
          _SummaryStatBox(label: 'Exercises',  value: '${session.exercises.length}',   color: AppColors.green),
          const SizedBox(width: 12),
          _SummaryStatBox(label: 'Total Sets', value: '${session.totalSets}',           color: AppColors.amber),
        ]),
        const SizedBox(height: 24),
        const Text('Exercises done',
            style: TextStyle(
                color: AppColors.subtext, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: session.exercises.length,
            itemBuilder: (_, i) {
              final e = session.exercises[i];
              return FitCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Text('🏋️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.name,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                        '${e.reps} reps · '
                            '${e.weightKg > 0 ? '${e.weightKg.toStringAsFixed(0)}kg' : 'bodyweight'}',
                        style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
                  ])),
                  Text('${e.sets} SETS',
                      style: const TextStyle(
                          color: AppColors.purpleLight, fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Start New Session',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — FOOD INTAKE
// ─────────────────────────────────────────────────────────────────────────────

class _FoodTab extends ConsumerStatefulWidget {
  final Member member;
  const _FoodTab({required this.member});

  @override
  ConsumerState<_FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends ConsumerState<_FoodTab> {
  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(todayMealsProvider(widget.member.id));

    return SafeArea(
      child: Column(children: [
        // ── Header ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            const Expanded(
                child: Text('FOOD INTAKE',
                    style: TextStyle(
                        color: AppColors.text, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: 0.5))),
            _StatusPill(
                label: DateFormat('MMM d').format(DateTime.now()),
                color: AppColors.subtext),
            const SizedBox(width: 8),
            mealsAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data:    (meals) => _StatusPill(
                  label: meals.isEmpty ? 'Start Logging' : '${meals.length} meals',
                  color: meals.isEmpty
                      ? AppColors.green
                      : AppColors.purpleLight),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Meals list label ────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('MEALS TODAY',
                style: TextStyle(
                    color: AppColors.subtext, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ),
        ),
        const SizedBox(height: 10),

        // ── Meals list ──────────────────────────────────────────────
        Expanded(
          child: mealsAsync.when(
            loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.purple)),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (meals) => meals.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🥗', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              const Text('No food logged yet.',
                  style: TextStyle(color: AppColors.subtext, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Tap Add Food to start tracking!',
                  style: TextStyle(
                      color: AppColors.subtext.withValues(alpha: 0.6), fontSize: 12)),
            ]))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: meals.length,
              itemBuilder: (_, i) => _MealCard(
                meal: meals[i],
                onDelete: () async {
                  await Supabase.instance.client
                      .from('meal_logs')
                      .delete()
                      .eq('id', meals[i].id);
                  ref.invalidate(todayMealsProvider(widget.member.id));
                },
              ),
            ),
          ),
        ),

        // ── Add food button ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAddMeal(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Food',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ),
      ]),
    );
  }

  void _showAddMeal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMealSheet(
          memberId: widget.member.id,
          onSaved: () => ref.invalidate(todayMealsProvider(widget.member.id))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — PROGRESS
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressTab extends ConsumerStatefulWidget {
  final Member member;
  const _ProgressTab({required this.member});

  @override
  ConsumerState<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends ConsumerState<_ProgressTab> {
  @override
  Widget build(BuildContext context) {
    final weeklyAsync  = ref.watch(weeklyWorkoutsProvider(widget.member.id));
    final monthlyAsync = ref.watch(monthlyWorkoutsProvider(widget.member.id));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Progress',
                  style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
            ])),
            // Calendar icon — view a specific day's activities
            Container(
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
              ),
              child: IconButton(
                onPressed: () => _showCalendar(context),
                icon: const Icon(Icons.calendar_month_outlined,
                    color: AppColors.purpleLight, size: 20),
                tooltip: 'View by date',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Weekly chart ────────────────────────────────────────
          const _SectionLabel(label: 'This Week — Workouts per Day'),
          const SizedBox(height: 12),
          weeklyAsync.when(
            loading: () => const _LoadingCard(height: 180),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (data) => _WeeklyChartCard(weeklyData: data),
          ),
          const SizedBox(height: 24),

          // ── Monthly chart ───────────────────────────────────────
          const _SectionLabel(label: 'This Month — Daily Workouts'),
          const SizedBox(height: 12),
          monthlyAsync.when(
            loading: () => const _LoadingCard(height: 180),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (data) => _MonthlyChartCard(monthlyData: data),
          ),
          const SizedBox(height: 24),

          // ── Summary stats ───────────────────────────────────────
          monthlyAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (data) {
              final totalWorkouts = data.values.fold(0, (s, v) => s + v);
              final activeDays    = data.values.where((v) => v > 0).length;
              final now = DateTime.now();
              final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
              return Row(children: [
                _SummaryStatBox(label: 'Workouts',    value: '$totalWorkouts', color: AppColors.purple),
                const SizedBox(width: 12),
                _SummaryStatBox(label: 'Active Days', value: '$activeDays',    color: AppColors.green),
                const SizedBox(width: 12),
                _SummaryStatBox(
                    label: 'Consistency',
                    value: daysInMonth > 0
                        ? '${((activeDays / daysInMonth) * 100).toStringAsFixed(0)}%'
                        : '0%',
                    color: AppColors.amber),
              ]);
            },
          ),
        ],
      ),
    );
  }

  // ── Calendar: pick date → show activities ─────────────────────────────────

  void _showCalendar(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => MemberCalendarScreen(memberId: widget.member.id),
      ),
    );
  }
}

// ── Day Activities Sheet (Calendar modal) ─────────────────────────────────────

class _DayActivitiesSheet extends StatelessWidget {
  final String   memberId;
  final DateTime date;
  const _DayActivitiesSheet({required this.memberId, required this.date});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final label   = DateFormat('EEEE, MMMM d').format(date);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => FutureBuilder<Map<String, List>>(
        future: _fetchDayActivities(dateStr),
        builder: (ctx, snap) {
          return Column(children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.calendar_today, color: AppColors.purpleLight, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                const Divider(color: AppColors.cardBorder),
              ]),
            ),

            if (!snap.hasData)
              const Expanded(child: Center(
                  child: CircularProgressIndicator(color: AppColors.purple)))
            else
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    // ── Workouts ────────────────────────────────────
                    const Text('Workouts',
                        style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (snap.data!['workouts']!.isEmpty)
                      _EmptyDay(label: 'No workouts on this day')
                    else
                      ...snap.data!['workouts']!.map((r) {
                        final w = WorkoutLog.fromMap(r as Map<String, dynamic>);
                        return FitCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            const Text('🏋️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(w.workoutType,
                                  style: const TextStyle(
                                      color: AppColors.text, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              if (w.duration != null)
                                Text('${w.duration} min',
                                    style: const TextStyle(
                                        color: AppColors.subtext, fontSize: 12)),
                            ])),
                          ]),
                        );
                      }),

                    const SizedBox(height: 20),

                    // ── Food ─────────────────────────────────────────
                    const Text('Food Intake',
                        style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (snap.data!['meals']!.isEmpty)
                      _EmptyDay(label: 'No food logged on this day')
                    else
                      ...snap.data!['meals']!.map((r) {
                        final m = MealLog.fromMap(r as Map<String, dynamic>);
                        const icons = {'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍎'};
                        return FitCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            Text(icons[m.mealType.toLowerCase()] ?? '🍽️',
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m.foodName,
                                  style: const TextStyle(
                                      color: AppColors.text, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  m.mealType[0].toUpperCase() +
                                      m.mealType.substring(1),
                                  style: const TextStyle(
                                      color: AppColors.subtext, fontSize: 11)),
                            ])),
                            if (m.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    m.imageUrl!, width: 40, height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                              ),
                          ]),
                        );
                      }),
                  ],
                ),
              ),
          ]);
        },
      ),
    );
  }

  Future<Map<String, List>> _fetchDayActivities(String dateStr) async {
    final workoutsRes = await Supabase.instance.client
        .from('workout_logs').select()
        .eq('member_id', memberId).eq('date', dateStr);
    final mealsRes = await Supabase.instance.client
        .from('meal_logs').select()
        .eq('member_id', memberId).eq('date', dateStr);
    return {
      'workouts': workoutsRes as List,
      'meals':    mealsRes    as List,
    };
  }
}

class _EmptyDay extends StatelessWidget {
  final String label;
  const _EmptyDay({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label,
        style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
  );
}

// ── Monthly bar chart card ────────────────────────────────────────────────────

class _MonthlyChartCard extends StatelessWidget {
  final Map<int, int> monthlyData;
  const _MonthlyChartCard({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final now         = DateTime.now();
    final today       = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final maxVal      = monthlyData.values.fold(0, max).toDouble();
    final chartMax    = max(maxVal, 3.0);

    final groups = List.generate(daysInMonth, (i) {
      final day     = i + 1;
      final count   = monthlyData[day] ?? 0;
      final isToday = day == today;
      final hasDone = count > 0;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: hasDone || isToday
                ? max(count.toDouble(), isToday ? 0.15 : 0)
                : 0,
            width: 7,
            color: isToday && hasDone
                ? const Color(0xFF00E5A0)
                : isToday
                ? const Color(0xFF00E5A0).withValues(alpha: 0.35)
                : hasDone
                ? AppColors.purple
                : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return FitCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        SizedBox(
          height: 150,
          child: BarChart(BarChartData(
            barGroups: groups,
            maxY: chartMax + 1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 5,
                getTitlesWidget: (x, _) {
                  final day = x.toInt() + 1;
                  if (day % 5 != 0 && day != 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('$day',
                        style: TextStyle(
                            color: day == today
                                ? const Color(0xFF00E5A0)
                                : AppColors.subtext,
                            fontSize: 10)),
                  );
                },
              )),
            ),
          )),
        ),
        const SizedBox(height: 8),
        const Text('🟢 today  ·  🟣 completed  ·  grouped by day of month',
            style: TextStyle(color: AppColors.subtext, fontSize: 10.5)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — TRAINER CHAT
// ─────────────────────────────────────────────────────────────────────────────

class _ChatPair {
  final String a, b;
  const _ChatPair(this.a, this.b);
  @override bool operator ==(Object o) => o is _ChatPair && a == o.a && b == o.b;
  @override int get hashCode => Object.hash(a, b);
}

final _chatStreamProvider =
StreamProvider.family<List<ChatMessage>, _ChatPair>((ref, pair) =>
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('timestamp')
        .map((list) => list
        .map((m) => ChatMessage.fromMap(m))
        .where((m) =>
    (m.senderId == pair.a && m.receiverId == pair.b) ||
        (m.senderId == pair.b && m.receiverId == pair.a))
        .toList()));

class _ChatTab extends ConsumerStatefulWidget {
  final Member member;
  const _ChatTab({required this.member});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _msgCtrl = TextEditingController();
  final _picker  = ImagePicker();
  bool _sending  = false;
  int? _tappedIdx;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String myId, String otherId,
      {String text = '', String? imgUrl}) async {
    if (text.trim().isEmpty && imgUrl == null) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id':    myId,
        'receiver_id':  otherId,
        'message':      text.trim(),
        'timestamp':    DateTime.now().toIso8601String(),
        'message_type': imgUrl != null ? 'image' : 'text',
        if (imgUrl != null) 'image_url': imgUrl,
      });
    } catch (_) {}
    setState(() => _sending = false);
  }

  Future<void> _pickAndSendImage(String myId, String otherId) async {
    try {
      final xf = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 75);
      if (xf == null) return;
      setState(() => _sending = true);
      final bytes    = await xf.readAsBytes();
      final fileName = 'chat/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('uploads').uploadBinary(
          fileName, bytes,
          fileOptions:
          const FileOptions(contentType: 'image/jpeg', upsert: false));
      final url = Supabase.instance.client.storage
          .from('uploads')
          .getPublicUrl(fileName);
      await _send(myId, otherId, imgUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppColors.red));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _smartTimestamp(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dt.year, dt.month, dt.day);
    final tStr  = DateFormat('h:mm a').format(dt);
    if (day == today) return tStr;
    if (today.difference(day).inDays == 1) return 'Yesterday $tStr';
    return '${DateFormat('MMM d').format(dt)}, $tStr';
  }

  @override
  Widget build(BuildContext context) {
    final myUser = ref.watch(authProvider).user;
    if (widget.member.trainerId == null || myUser == null) {
      return const SafeArea(
          child: Center(child: Text('No trainer assigned yet.',
              style: TextStyle(color: AppColors.subtext))));
    }

    return FutureBuilder<dynamic>(
      future: Supabase.instance.client
          .from('trainers')
          .select()
          .eq('id', widget.member.trainerId!)
          .maybeSingle(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const FullScreenLoader();
        final trainerName   = snap.data?['full_name'] as String? ?? 'Trainer';
        final trainerUserId = snap.data?['user_id']   as String? ?? widget.member.trainerId!;
        final pair          = _ChatPair(myUser.id, trainerUserId);
        final msgsAsync     = ref.watch(_chatStreamProvider(pair));

        return SafeArea(
          child: Column(children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF13131E),
                border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
              ),
              child: Row(children: [
                AppAvatar(name: trainerName, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trainerName,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Row(children: [
                    Container(width: 7, height: 7,
                        decoration: const BoxDecoration(
                            color: AppColors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Your Trainer',
                        style: TextStyle(
                            color: AppColors.green, fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ]),
                ])),
              ]),
            ),

            // ── Messages (newest at bottom, like Messenger) ─────────
            Expanded(
              child: msgsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.purple)),
                error:   (_, __) => const Center(
                    child: Text('Could not load messages.',
                        style: TextStyle(color: AppColors.subtext))),
                data: (msgs) {
                  if (msgs.isEmpty) {
                    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('👋', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 12),
                      Text('Say hi to your trainer!',
                          style: TextStyle(color: AppColors.subtext, fontSize: 13)),
                    ]));
                  }
                  // reverse:true → index 0 rendered at bottom → show msgs in
                  // reverse order so newest (last in list) becomes index 0
                  final reversed = msgs.reversed.toList();
                  return GestureDetector(
                    onTap: () => setState(() => _tappedIdx = null),
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: reversed.length,
                      itemBuilder: (_, i) {
                        final m    = reversed[i];
                        final isMe = m.senderId == myUser.id;
                        final showTs = _tappedIdx == i;
                        return GestureDetector(
                          onTap: () => setState(
                                  () => _tappedIdx = _tappedIdx == i ? null : i),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                                    child: AppAvatar(name: trainerName, size: 24)),
                              _ChatBubble(message: m, isMe: isMe),
                              if (showTs)
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 4, left: 4, right: 4),
                                    child: Text(_smartTimestamp(m.timestamp),
                                        style: const TextStyle(
                                            color: AppColors.subtext,
                                            fontSize: 10.5))),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: const BoxDecoration(
                color: Color(0xFF13131E),
                border: Border(
                    top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: _sending
                      ? null
                      : () => _pickAndSendImage(myUser.id, trainerUserId),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.subtext, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Message your trainer…',
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
                    onSubmitted: (_) =>
                        _send(myUser.id, trainerUserId, text: _msgCtrl.text),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending
                      ? null
                      : () => _send(myUser.id, trainerUserId, text: _msgCtrl.text),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.purple, AppColors.purpleLight]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.35),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Add Exercise ──────────────────────────────────────────────────────────────

class _AddExerciseSheet extends StatefulWidget {
  final void Function(WorkoutExercise) onAdd;
  const _AddExerciseSheet({required this.onAdd});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  // Empty controllers — hint text shows placeholder, disappears on typing
  final _nameCtrl   = TextEditingController();
  final _setsCtrl   = TextEditingController();
  final _repsCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter exercise name.');
      return;
    }
    final sets   = int.tryParse(_setsCtrl.text)      ?? 1;
    final reps   = int.tryParse(_repsCtrl.text)      ?? 1;
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    widget.onAdd(WorkoutExercise(
        name: _nameCtrl.text.trim(),
        sets: sets, reps: reps, weightKg: weight));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Add Exercise',
              style: TextStyle(
                  color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          _SheetLabel('EXERCISE NAME'),
          const SizedBox(height: 8),
          TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'e.g. Bench Press'),
              onSubmitted: (_) => _submit()),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SheetLabel('SETS'),
              const SizedBox(height: 8),
              TextField(
                  controller: _setsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(hintText: '3')),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SheetLabel('REPS'),
              const SizedBox(height: 8),
              TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(hintText: '10')),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SheetLabel('KG'),
              const SizedBox(height: 8),
              TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(hintText: '0')),
            ])),
          ]),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          const SizedBox(height: 24),

          SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Add Exercise',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))),
        ]),
  );
}

// ── Add Meal Sheet (Food only — no nutrition fields) ──────────────────────────

class _AddMealSheet extends StatefulWidget {
  final String      memberId;
  final VoidCallback onSaved;
  const _AddMealSheet({required this.memberId, required this.onSaved});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  String  _mealType = 'Breakfast';
  final  _foodCtrl  = TextEditingController();
  XFile?  _photo;
  bool    _saving   = false;
  String? _error;

  static const _types      = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  static const _typeIcons  = {
    'Breakfast': '🌅', 'Lunch': '☀️', 'Dinner': '🌙', 'Snack': '🍎'
  };

  @override
  void dispose() {
    _foodCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final xf = await ImagePicker()
          .pickImage(source: src, imageQuality: 70, maxWidth: 800);
      if (xf != null) setState(() => _photo = xf);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_foodCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a food name.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      String? imgUrl;
      if (_photo != null) {
        final bytes    = await _photo!.readAsBytes();
        final fileName = 'meals/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('uploads').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imgUrl = Supabase.instance.client.storage
            .from('uploads')
            .getPublicUrl(fileName);
      }
      await Supabase.instance.client.from('meal_logs').insert({
        'member_id': widget.memberId,
        'meal_type': _mealType.toLowerCase(),
        'food_name': _foodCtrl.text.trim(),
        'date':      DateFormat('yyyy-MM-dd').format(DateTime.now()),
        if (imgUrl != null) 'image_url': imgUrl,
      });
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      const Text('Add Food',
          style: TextStyle(
              color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),

      // Meal type chips
      _SheetLabel('MEAL TYPE'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
        final sel = _mealType == t;
        return GestureDetector(
            onTap: () => setState(() => _mealType = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(
                    colors: [AppColors.purple, AppColors.purpleLight])
                    : null,
                color: sel ? null : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? Colors.transparent : AppColors.cardBorder),
              ),
              child: Text('${_typeIcons[t]} $t',
                  style: TextStyle(
                      color: sel ? Colors.white : AppColors.subtextMid,
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ));
      }).toList()),
      const SizedBox(height: 18),

      // Food name
      _SheetLabel('FOOD NAME'),
      const SizedBox(height: 8),
      TextField(
          controller: _foodCtrl,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
              hintText: 'e.g. Grilled chicken breast')),
      const SizedBox(height: 18),

      // Photo
      _SheetLabel('PHOTO (optional)'),
      const SizedBox(height: 10),
      Row(children: [
        _PhotoButton(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            onTap: () => _pickPhoto(ImageSource.camera)),
        const SizedBox(width: 10),
        _PhotoButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: () => _pickPhoto(ImageSource.gallery)),
        if (_photo != null) ...[
          const SizedBox(width: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(_photo!.path),
                  width: 56, height: 56, fit: BoxFit.cover)),
          const SizedBox(width: 6),
          GestureDetector(
              onTap: () => setState(() => _photo = null),
              child: const Icon(Icons.close,
                  color: AppColors.subtext, size: 18)),
        ],
      ]),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
      ],
      const SizedBox(height: 24),

      SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Text('Save Food',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED / HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final VoidCallback    onDelete;
  const _ExerciseCard({required this.exercise, required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FitCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: const Text('🏋️', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.name,
              style: const TextStyle(
                  color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
              '${exercise.reps} reps · '
                  '${exercise.weightKg > 0 ? '${exercise.weightKg.toStringAsFixed(0)}kg' : 'bodyweight'}',
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
        ])),
        Text('${exercise.sets}',
            style: const TextStyle(
                color: AppColors.purpleLight, fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        const Text('SETS',
            style: TextStyle(color: AppColors.subtext, fontSize: 9,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 20)),
      ]),
    ),
  );
}

// ── Meal card (simplified — no nutrition data) ────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealLog      meal;
  final VoidCallback onDelete;
  const _MealCard({required this.meal, required this.onDelete});

  static const _icons = {
    'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍎'
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FitCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Text(_icons[meal.mealType.toLowerCase()] ?? '🍽️',
            style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meal.foodName,
              style: const TextStyle(
                  color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
              meal.mealType[0].toUpperCase() + meal.mealType.substring(1),
              style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
        ])),
        if (meal.imageUrl != null) ...[
          const SizedBox(width: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(meal.imageUrl!,
                  width: 44, height: 44, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        ],
        const SizedBox(width: 8),
        GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 20)),
      ]),
    ),
  );
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool        isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) => Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 4, bottom: 2),
      constraints:
      BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: message.messageType == 'image'
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      child: message.messageType == 'image' && message.imageUrl != null
          ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(message.imageUrl!, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox(width: 180, height: 120,
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.purple))),
              errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.subtext, size: 32))))
          : Text(message.message,
          style: TextStyle(
              color: isMe ? Colors.white : AppColors.text,
              fontSize: 14, height: 1.4)),
    ),
  );
}

// ─── Small reusable pieces ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700));
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   dot;
  const _StatusPill({required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (dot) ...[
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
      ],
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _SummaryStatBox extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _SummaryStatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: FitCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
      ]),
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5))),
    alignment: Alignment.center,
    child: const CircularProgressIndicator(
        color: AppColors.purple, strokeWidth: 2),
  );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.subtext, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _PhotoButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.subtext, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.subtext, fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}