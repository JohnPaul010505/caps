import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'member_home_screen.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final workoutHistoryProvider =
    FutureProvider.family<List<WorkoutLog>, String>((ref, memberId) async {
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final res = await Supabase.instance.client
      .from('workout_logs')
      .select()
      .eq('member_id', memberId)
      .gte('date', DateFormat('yyyy-MM-dd').format(thirtyDaysAgo))
      .order('date');
  return (res as List).map((r) => WorkoutLog.fromMap(r)).toList();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.text),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Progress',
            style: TextStyle(color: AppColors.text, fontSize: 17,
              fontWeight: FontWeight.w700)),
          Text('Last 30 days',
            style: TextStyle(color: AppColors.subtext, fontSize: 12)),
        ]),
      ),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(
          color: AppColors.purple)),
        error: (_, __) => const Center(child: Text('Error loading profile.')),
        data: (member) {
          if (member == null) return const Center(
            child: Text('No profile found.',
              style: TextStyle(color: AppColors.subtext)));
          return _ProgressBody(member: member);
        },
      ),
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  final Member member;
  const _ProgressBody({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutHistoryProvider(member.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // ── Weight Trend Chart ────────────────────────────────────────
        _WeightTrendCard(member: member),
        const SizedBox(height: 16),

        // ── Stats Row ─────────────────────────────────────────────────
        workoutsAsync.when(
          loading: () => const SizedBox(height: 80,
            child: Center(child: CircularProgressIndicator(
              color: AppColors.purple))),
          error: (_, __) => const SizedBox.shrink(),
          data: (workouts) {
            final totalCals = workouts.fold<int>(
                0, (s, w) => s + (w.caloriesBurned ?? 0));
            final weightStart = member.weight ?? 0;
            final weightNow   = (member.weight ?? 0) - 2.7; // mock delta
            final lostKg      = (weightStart - weightNow).abs();

            return Row(children: [
              Expanded(child: _BigStatCard(
                value: '-${lostKg.toStringAsFixed(1)} kg',
                label: 'Lost this month',
                color: AppColors.green,
              )),
              const SizedBox(width: 12),
              Expanded(child: _BigStatCard(
                value: '${workouts.length}',
                label: 'Workouts done',
                color: AppColors.purple,
              )),
            ]);
          },
        ),
        const SizedBox(height: 16),

        // ── AI Prediction ────────────────────────────────────────────
        _AiPredictionCard(member: member),
        const SizedBox(height: 16),

        // ── Recent Workouts ──────────────────────────────────────────
        const Text('Recent Workouts',
          style: TextStyle(color: AppColors.text, fontSize: 16,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        workoutsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(
            color: AppColors.purple)),
          error: (_, __) => const SizedBox.shrink(),
          data: (workouts) => workouts.isEmpty
            ? FitCard(child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No workouts logged yet.',
                    style: TextStyle(color: AppColors.subtext)))))
            : FitCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workouts.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.cardBorder, height: 1),
                  itemBuilder: (_, i) {
                    final w = workouts[i];
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏋️', style: TextStyle(fontSize: 16)),
                      ),
                      title: Text(w.workoutType,
                        style: const TextStyle(color: AppColors.text,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(w.date,
                        style: const TextStyle(
                          color: AppColors.subtext, fontSize: 12)),
                      trailing: w.duration != null
                        ? Text('${w.duration} min',
                            style: const TextStyle(
                              color: AppColors.purpleLight, fontSize: 12,
                              fontWeight: FontWeight.w600))
                        : null,
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }
}

// ─── Weight Trend Card ────────────────────────────────────────────────────────

class _WeightTrendCard extends StatelessWidget {
  final Member member;
  const _WeightTrendCard({required this.member});

  @override
  Widget build(BuildContext context) {
    // Mock weekly weight data — replace with real weight_logs table
    final startWeight = member.weight ?? 185;
    final weightPoints = [
      startWeight,
      startWeight - 1.5,
      startWeight - 3.2,
      startWeight - 4.8,
    ];

    final spots = List.generate(weightPoints.length,
        (i) => FlSpot(i.toDouble(), weightPoints[i]));

    final minY = weightPoints.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = weightPoints.reduce((a, b) => a > b ? a : b) + 2;

    return FitCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weight trend (lbs)',
          style: TextStyle(color: AppColors.text, fontSize: 15,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.cardBorder, strokeWidth: 0.5),
              ),
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
                    reservedSize: 24,
                    getTitlesWidget: (val, meta) {
                      const labels = ['W1', 'W2', 'W3', 'W4'];
                      final i = val.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox();
                      final isLast = i == labels.length - 1;
                      return Text(labels[i],
                        style: TextStyle(
                          color: isLast ? AppColors.purpleLight : AppColors.subtext,
                          fontSize: 11,
                          fontWeight: isLast ? FontWeight.w700 : FontWeight.normal,
                        ));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: 3,
              minY: minY, maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.purple,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                      radius: i == spots.length - 1 ? 5 : 3,
                      color: i == spots.length - 1
                          ? AppColors.purpleLight
                          : AppColors.purple,
                      strokeWidth: 1.5,
                      strokeColor: AppColors.background,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.purple.withOpacity(0.25),
                        AppColors.purple.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Start: ${weightPoints.first.toStringAsFixed(0)} lbs',
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
            Text('Now: ${weightPoints.last.toStringAsFixed(1)} lbs ▼',
              style: const TextStyle(color: AppColors.purpleLight, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ],
        ),
      ]),
    );
  }
}

// ─── Big Stat Card ───────────────────────────────────────────────────────────

class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BigStatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => FitCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
        style: TextStyle(color: color, fontSize: 26,
          fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label,
        style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
    ]),
  );
}

// ─── AI Prediction Card ───────────────────────────────────────────────────────

class _AiPredictionCard extends StatelessWidget {
  final Member member;
  const _AiPredictionCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final targetWeight = (member.weight ?? 185) - 6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purpleLight.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text('🤖', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Prediction',
            style: TextStyle(color: AppColors.purpleLight, fontSize: 13,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            "At this rate, you'll reach your goal weight of "
            '${targetWeight.toStringAsFixed(0)} lbs in about 6 weeks.',
            style: const TextStyle(color: AppColors.text, fontSize: 13,
              height: 1.4)),
        ])),
      ]),
    );
  }
}
