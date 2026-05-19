import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class TrainerMemberProgressScreen extends ConsumerWidget {
  final Member member;
  const TrainerMemberProgressScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.text),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.fullName,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const Text('Progress Overview',
              style: TextStyle(color: AppColors.subtext, fontSize: 12)),
        ]),
      ),
      body: _ProgressBody(member: member),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ProgressBody extends StatefulWidget {
  final Member member;
  const _ProgressBody({required this.member});

  @override
  State<_ProgressBody> createState() => _ProgressBodyState();
}

class _ProgressBodyState extends State<_ProgressBody> {
  bool _loading = true;
  List<WorkoutLog> _workouts = [];
  List<MealLog>    _meals    = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final thirtyAgo = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 30)));
    try {
      final wRes = await Supabase.instance.client
          .from('workout_logs')
          .select()
          .eq('member_id', widget.member.id)
          .gte('date', thirtyAgo)
          .order('date', ascending: false);

      final mRes = await Supabase.instance.client
          .from('meal_logs')
          .select()
          .eq('member_id', widget.member.id)
          .gte('date', thirtyAgo)
          .order('date', ascending: false);

      if (mounted) {
        setState(() {
          _workouts = (wRes as List)
              .map((r) => WorkoutLog.fromMap(r as Map<String, dynamic>))
              .toList();
          _meals = (mRes as List)
              .map((r) => MealLog.fromMap(r as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalCals =>
      _workouts.fold(0, (s, w) => s + (w.caloriesBurned ?? 0));

  int get _totalMealCals =>
      _meals.fold(0, (s, m) => s + (m.calories ?? 0));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.purple));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Member info card ──────────────────────────────────────
          _MemberInfoCard(member: widget.member),
          const SizedBox(height: 16),

          // ── Summary stats ─────────────────────────────────────────
          Row(children: [
            _StatBox(
                value: '${_workouts.length}',
                label: 'Workouts\n30 days',
                color: AppColors.purple),
            const SizedBox(width: 10),
            _StatBox(
                value: '${_meals.length}',
                label: 'Meals\n30 days',
                color: AppColors.green),
            const SizedBox(width: 10),
            _StatBox(
                value: _fmtCals(_totalCals),
                label: 'Cal\nBurned',
                color: AppColors.amber),
            const SizedBox(width: 10),
            _StatBox(
                value: _fmtCals(_totalMealCals),
                label: 'Cal\nEaten',
                color: AppColors.blue),
          ]),
          const SizedBox(height: 16),

          // ── Body metrics ──────────────────────────────────────────
          _BodyMetricsCard(member: widget.member),
          const SizedBox(height: 16),

          // ── Workout frequency chart (last 7 days) ─────────────────
          if (_workouts.isNotEmpty) ...[
            _WorkoutFrequencyCard(workouts: _workouts),
            const SizedBox(height: 16),
          ],

          // ── Recent workouts ───────────────────────────────────────
          Row(children: [
            const Expanded(
              child: Text('Recent Workouts',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            Text('Last 30 days',
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          _workouts.isEmpty
              ? FitCard(
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No workouts logged in the last 30 days.',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 13)),
              ))
              : FitCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _workouts.length,
              separatorBuilder: (_, __) => const Divider(
                  color: AppColors.cardBorder, height: 1),
              itemBuilder: (_, i) => _WorkoutTile(w: _workouts[i]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Recent meals ──────────────────────────────────────────
          Row(children: [
            const Expanded(
              child: Text('Recent Meals',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            Text('Last 30 days',
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          _meals.isEmpty
              ? FitCard(
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No meals logged in the last 30 days.',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 13)),
              ))
              : FitCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _meals.length,
              separatorBuilder: (_, __) => const Divider(
                  color: AppColors.cardBorder, height: 1),
              itemBuilder: (_, i) => _MealTile(m: _meals[i]),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCals(int val) =>
      val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : '$val';
}

// ─── Member info card ─────────────────────────────────────────────────────────

class _MemberInfoCard extends StatelessWidget {
  final Member member;
  const _MemberInfoCard({required this.member});

  @override
  Widget build(BuildContext context) => FitCard(
    child: Row(children: [
      AppAvatar(name: member.fullName, size: 56),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.fullName,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (member.age != null || member.gender != null)
                Text(
                  [
                    if (member.age != null) '${member.age} yrs',
                    if (member.gender != null) member.gender!,
                  ].join('  •  '),
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 12),
                ),
              if (member.goal != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.flag_outlined,
                      color: AppColors.purpleLight, size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(member.goal!,
                        style: const TextStyle(
                            color: AppColors.purpleLight,
                            fontSize: 12)),
                  ),
                ]),
              ],
            ]),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        StatusBadge(
            status: member.isExpiringSoon
                ? 'Exp. Soon'
                : member.membershipStatus),
        if (member.membershipType != null) ...[
          const SizedBox(height: 6),
          Text(member.membershipType!,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 11)),
        ],
      ]),
    ]),
  );
}

// ─── Body metrics card ────────────────────────────────────────────────────────

class _BodyMetricsCard extends StatelessWidget {
  final Member member;
  const _BodyMetricsCard({required this.member});

  String get _bmi {
    if (member.weight == null || member.height == null || member.height == 0) {
      return '—';
    }
    final h = member.height! / 100;
    return (member.weight! / (h * h)).toStringAsFixed(1);
  }

  String get _bmiCategory {
    if (member.weight == null || member.height == null) return '';
    final h = member.height! / 100;
    final bmi = member.weight! / (h * h);
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) => FitCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Body Metrics',
          style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      Row(children: [
        _Metric(
            emoji: '⚖️',
            value: member.weight != null
                ? '${member.weight!.toStringAsFixed(1)} kg'
                : '—',
            label: 'Weight'),
        const SizedBox(width: 10),
        _Metric(
            emoji: '📏',
            value: member.height != null
                ? '${member.height!.toStringAsFixed(0)} cm'
                : '—',
            label: 'Height'),
        const SizedBox(width: 10),
        _Metric(
            emoji: '📊',
            value: _bmi,
            label: _bmiCategory.isEmpty ? 'BMI' : _bmiCategory),
      ]),
      if (member.contactNumber != null ||
          member.emergencyContact != null) ...[
        const SizedBox(height: 14),
        const Divider(color: AppColors.cardBorder, height: 1),
        const SizedBox(height: 14),
        if (member.contactNumber != null)
          _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: member.contactNumber!),
        if (member.emergencyContact != null)
          _InfoRow(
              icon: Icons.emergency_outlined,
              label: 'Emergency',
              value: member.emergencyContact!),
      ],
    ]),
  );
}

class _Metric extends StatelessWidget {
  final String emoji, value, label;
  const _Metric(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                color: AppColors.subtext, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, color: AppColors.subtext, size: 15),
      const SizedBox(width: 8),
      Text('$label: ',
          style: const TextStyle(
              color: AppColors.subtext, fontSize: 12)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}

// ─── Workout frequency chart (last 7 days) ────────────────────────────────────

class _WorkoutFrequencyCard extends StatelessWidget {
  final List<WorkoutLog> workouts;
  const _WorkoutFrequencyCard({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final Map<int, int> countsByDay = {};
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      countsByDay[6 - i] =
          workouts.where((w) => w.date == key).length;
    }

    final maxY =
    countsByDay.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    final chartMax = maxY < 2 ? 3.0 : maxY + 1;

    final groups = List.generate(7, (i) {
      final count = countsByDay[i] ?? 0;
      final isToday = i == 6;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: count.toDouble(),
          width: 22,
          color: isToday
              ? AppColors.purpleLight
              : count > 0
              ? AppColors.purple
              : AppColors.cardBorder,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ]);
    });

    final dayLabels = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return i == 6 ? 'Today' : DateFormat('E').format(d);
    });

    return FitCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Workouts — Last 7 Days',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: BarChart(BarChartData(
            barGroups: groups,
            maxY: chartMax,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (val, _) {
                    final i = val.toInt();
                    if (i < 0 || i >= dayLabels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(dayLabels[i],
                          style: TextStyle(
                              color: i == 6
                                  ? AppColors.purpleLight
                                  : AppColors.subtext,
                              fontSize: 9)),
                    );
                  },
                ),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

// ─── Workout tile (in list) ───────────────────────────────────────────────────

class _WorkoutTile extends StatelessWidget {
  final WorkoutLog w;
  const _WorkoutTile({required this.w});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text('🏋️', style: TextStyle(fontSize: 16)),
    ),
    title: Text(w.workoutType,
        style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600)),
    subtitle: Text(w.date,
        style:
        const TextStyle(color: AppColors.subtext, fontSize: 12)),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (w.duration != null)
          Text('${w.duration} min',
              style: const TextStyle(
                  color: AppColors.purpleLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        if (w.caloriesBurned != null)
          Text('${w.caloriesBurned} cal',
              style: const TextStyle(
                  color: AppColors.amber, fontSize: 11)),
      ],
    ),
  );
}

// ─── Meal tile (in list) ──────────────────────────────────────────────────────

class _MealTile extends StatelessWidget {
  final MealLog m;
  const _MealTile({required this.m});

  static const _icons = {
    'breakfast': '🌅',
    'lunch':     '☀️',
    'dinner':    '🌙',
    'snack':     '🍎',
  };

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(
        _icons[m.mealType.toLowerCase()] ?? '🍽️',
        style: const TextStyle(fontSize: 26)),
    title: Text(m.foodName,
        style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600)),
    subtitle: Text(
        '${m.mealType[0].toUpperCase()}${m.mealType.substring(1)}  ·  ${m.date}',
        style:
        const TextStyle(color: AppColors.subtext, fontSize: 12)),
    trailing: m.calories != null
        ? Text('${m.calories} kcal',
        style: const TextStyle(
            color: AppColors.green,
            fontSize: 12,
            fontWeight: FontWeight.w600))
        : null,
  );
}

// ─── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color  color;
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.subtext, fontSize: 10)),
      ]),
    ),
  );
}