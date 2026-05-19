import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class MemberCalendarScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MemberCalendarScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberCalendarScreen> createState() =>
      _MemberCalendarScreenState();
}

class _MemberCalendarScreenState
    extends ConsumerState<MemberCalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay  = DateTime.now();

  // Maps "yyyy-MM-dd" → list of logs for the focused month
  Map<String, List<WorkoutLog>> _workoutsByDay = {};
  Map<String, List<MealLog>>    _mealsByDay    = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonth(_focusedMonth);
  }

  // ── Fetch all logs for a month ──────────────────────────────────────────────

  Future<void> _fetchMonth(DateTime month) async {
    setState(() => _loading = true);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay  = DateTime(month.year, month.month + 1, 0);
    final startStr = _fmt(firstDay);
    final endStr   = _fmt(lastDay);

    try {
      final wRes = await Supabase.instance.client
          .from('workout_logs')
          .select()
          .eq('member_id', widget.memberId)
          .gte('date', startStr)
          .lte('date', endStr);

      final mRes = await Supabase.instance.client
          .from('meal_logs')
          .select()
          .eq('member_id', widget.memberId)
          .gte('date', startStr)
          .lte('date', endStr);

      final Map<String, List<WorkoutLog>> wByDay = {};
      for (final r in (wRes as List)) {
        final w = WorkoutLog.fromMap(r as Map<String, dynamic>);
        wByDay.putIfAbsent(w.date, () => []).add(w);
      }
      final Map<String, List<MealLog>> mByDay = {};
      for (final r in (mRes as List)) {
        final m = MealLog.fromMap(r as Map<String, dynamic>);
        mByDay.putIfAbsent(m.date, () => []).add(m);
      }

      if (mounted) {
        setState(() {
          _workoutsByDay = wByDay;
          _mealsByDay    = mByDay;
          _loading       = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Month navigation ────────────────────────────────────────────────────────

  void _prevMonth() {
    final m = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    setState(() {
      _focusedMonth = m;
      // Keep selected day in same month if possible, else first day
      _selectedDay  = DateTime(m.year, m.month,
          _selectedDay.month == m.month ? _selectedDay.day : 1);
    });
    _fetchMonth(m);
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) {
      return;
    }
    final m = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    setState(() {
      _focusedMonth = m;
      _selectedDay  = DateTime(m.year, m.month, 1);
    });
    _fetchMonth(m);
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final selKey      = _fmt(_selectedDay);
    final dayWorkouts = _workoutsByDay[selKey] ?? [];
    final dayMeals    = _mealsByDay[selKey]    ?? [];
    final now = DateTime.now();
    final isCurrentMonth =
        _focusedMonth.year == now.year && _focusedMonth.month == now.month;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.text),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Activity Calendar',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          Text('Tap a day to see your log',
              style: TextStyle(color: AppColors.subtext, fontSize: 12)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Calendar card ───────────────────────────────────────────
          FitCard(
            child: Column(children: [
              // Month header
              Row(children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.text, size: 26),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: isCurrentMonth ? null : _nextMonth,
                  icon: Icon(Icons.chevron_right,
                      color: isCurrentMonth
                          ? AppColors.subtext.withValues(alpha: 0.3)
                          : AppColors.text,
                      size: 26),
                ),
              ]),

              // Day-of-week labels
              const SizedBox(height: 4),
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((d) => Expanded(
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.subtext,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 6),

              // Calendar grid
              _loading
                  ? const SizedBox(
                  height: 200,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.purple)))
                  : _buildGrid(now),

              // Legend
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Dot(color: AppColors.purple),
                const SizedBox(width: 4),
                const Text('Workout',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 11)),
                const SizedBox(width: 16),
                _Dot(color: AppColors.green),
                const SizedBox(width: 4),
                const Text('Food',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Day detail ─────────────────────────────────────────────
          _DayDetail(
            date:     _selectedDay,
            workouts: dayWorkouts,
            meals:    dayMeals,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime now) {
    final firstDay    = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    // weekday: Mon=1…Sun=7 → convert to Sun=0 offset
    final startOffset = firstDay.weekday % 7;
    final totalCells  = startOffset + daysInMonth;
    final rows        = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final idx    = row * 7 + col;
            final dayNum = idx - startOffset + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 50));
            }

            final date     = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            final dateStr  = _fmt(date);
            final hasWork  = (_workoutsByDay[dateStr]?.isNotEmpty) ?? false;
            final hasMeal  = (_mealsByDay[dateStr]?.isNotEmpty)    ?? false;
            final isToday  = _fmt(date) == _fmt(now);
            final isSel    = _fmt(date) == _fmt(_selectedDay);
            final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

            return Expanded(
              child: GestureDetector(
                onTap: isFuture ? null : () => setState(() => _selectedDay = date),
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.all(2),
                  decoration: isSel
                      ? BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.purple,
                      AppColors.purpleLight,
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  )
                      : isToday
                      ? BoxDecoration(
                    border: Border.all(
                        color: AppColors.purpleLight, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isFuture
                              ? AppColors.subtext.withValues(alpha: 0.35)
                              : isSel
                              ? Colors.white
                              : isToday
                              ? AppColors.purpleLight
                              : AppColors.text,
                          fontSize: 13,
                          fontWeight: (isSel || isToday)
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                      // Activity dots
                      if (!isFuture && (hasWork || hasMeal)) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasWork)
                              _Dot(
                                  color: isSel
                                      ? Colors.white
                                      : AppColors.purple,
                                  size: 5),
                            if (hasWork && hasMeal)
                              const SizedBox(width: 3),
                            if (hasMeal)
                              _Dot(
                                  color: isSel
                                      ? Colors.white70
                                      : AppColors.green,
                                  size: 5),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

// ─── Day Detail section ───────────────────────────────────────────────────────

class _DayDetail extends StatelessWidget {
  final DateTime         date;
  final List<WorkoutLog> workouts;
  final List<MealLog>    meals;

  const _DayDetail({
    required this.date,
    required this.workouts,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final label = isToday
        ? 'Today'
        : DateFormat('EEEE, MMMM d').format(date);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.event_note_outlined,
              color: AppColors.purpleLight, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
        ),
        if (workouts.isEmpty && meals.isEmpty)
          const Text('No activity',
              style: TextStyle(color: AppColors.subtext, fontSize: 12)),
      ]),
      const SizedBox(height: 16),

      // ── Workouts ──────────────────────────────────────────────────
      _SectionLabel(
        icon: '🏋️',
        label: 'Workouts',
        count: workouts.length,
        color: AppColors.purple,
      ),
      const SizedBox(height: 8),
      if (workouts.isEmpty)
        _EmptyCard(text: 'No workouts logged')
      else
        ...workouts.map((w) => _WorkoutCard(workout: w)),

      const SizedBox(height: 16),

      // ── Meals ─────────────────────────────────────────────────────
      _SectionLabel(
        icon: '🍽️',
        label: 'Food Intake',
        count: meals.length,
        color: AppColors.green,
      ),
      const SizedBox(height: 8),
      if (meals.isEmpty)
        _EmptyCard(text: 'No food logged')
      else
        ...meals.map((m) => _MealCard(meal: m)),
    ]);
  }
}

// ─── Section label row ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String icon, label;
  final int    count;
  final Color  color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(label,
        style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700)),
    const SizedBox(width: 8),
    if (count > 0)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text('$count',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
  ]);
}

// ─── Workout card ─────────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final WorkoutLog workout;
  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FitCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text('🏋️', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(workout.workoutType,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (workout.duration != null)
            Text('${workout.duration} min',
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 12)),
        ])),
        if (workout.caloriesBurned != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${workout.caloriesBurned}',
                style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Text('kcal',
                style: TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
          ]),
      ]),
    ),
  );
}

// ─── Meal card ────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealLog meal;
  const _MealCard({required this.meal});

  static const _icons = {
    'breakfast': '🌅',
    'lunch':     '☀️',
    'dinner':    '🌙',
    'snack':     '🍎',
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FitCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Text(_icons[meal.mealType.toLowerCase()] ?? '🍽️',
            style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meal.foodName,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(
              '${meal.mealType[0].toUpperCase()}${meal.mealType.substring(1)}',
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 11)),
        ])),
        if (meal.imageUrl != null) ...[
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(meal.imageUrl!,
                width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ],
        if (meal.calories != null) ...[
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${meal.calories}',
                style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Text('kcal',
                style: TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
          ]),
        ],
      ]),
    ),
  );
}

// ─── Empty state card ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) => FitCard(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    child: Text(text,
        style: const TextStyle(
            color: AppColors.subtext, fontSize: 13)),
  );
}

// ─── Small dot ───────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final Color  color;
  final double size;
  const _Dot({required this.color, this.size = 7});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}