import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'member_home_screen.dart';

const _workoutTypes = [
  'Cardio', 'Strength', 'HIIT', 'Yoga',
  'Cycling', 'Swimming', 'Boxing', 'Stretching',
];

class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  String  _workoutType = 'Cardio';
  final   _durationCtrl = TextEditingController();
  final   _calCtrl      = TextEditingController();
  bool    _saving = false;
  String? _error;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_durationCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter duration.');
      return;
    }
    final member = ref.read(memberProfileProvider).value;
    if (member == null) {
      setState(() => _error = 'Profile not found.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await Supabase.instance.client.from('workout_logs').insert({
        'member_id':      member.id,
        'workout_type':   _workoutType,
        'duration':       int.tryParse(_durationCtrl.text),
        'calories_burned': _calCtrl.text.isNotEmpty
            ? int.tryParse(_calCtrl.text)
            : null,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const BackButton(color: AppColors.text),
      title: const Text('Log Workout',
        style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // ── Workout Type Grid ────────────────────────────────────────
        const _Label('WORKOUT TYPE'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: _workoutTypes.map((t) {
            final selected = _workoutType == t;
            return GestureDetector(
              onTap: () => setState(() => _workoutType = t),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [
                          AppColors.purple, AppColors.purpleLight])
                      : null,
                  color: selected ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.cardBorder.withOpacity(0.5)),
                ),
                child: Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.subtextMid,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // ── Duration ─────────────────────────────────────────────────
        const _Label('DURATION (minutes)'),
        const SizedBox(height: 8),
        TextField(
          controller: _durationCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'e.g. 45'),
        ),
        const SizedBox(height: 16),

        // ── Calories ─────────────────────────────────────────────────
        const _Label('CALORIES BURNED (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _calCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'e.g. 320'),
        ),
        const SizedBox(height: 12),

        // Summary hint
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Text('🏋️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Logging $_workoutType on ${DateFormat('MMM d').format(DateTime.now())}',
              style: const TextStyle(
                color: AppColors.purpleLight, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 24),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withOpacity(0.3)),
            ),
            child: Text(_error!,
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
              : const Text('Save Workout'),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      color: AppColors.subtext, fontSize: 11,
      fontWeight: FontWeight.w600, letterSpacing: 0.5));
}
