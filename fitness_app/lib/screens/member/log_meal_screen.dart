import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'member_home_screen.dart';

const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key});

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  String _mealType = 'Breakfast';
  final _foodCtrl  = TextEditingController();
  final _calCtrl   = TextEditingController();
  final _protCtrl  = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _foodCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_foodCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a food name.');
      return;
    }
    final memberAsync = ref.read(memberProfileProvider);
    final member = memberAsync.value;
    if (member == null) {
      setState(() => _error = 'Profile not found.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await Supabase.instance.client.from('meal_logs').insert({
        'member_id': member.id,
        'meal_type': _mealType.toLowerCase(),
        'food_name': _foodCtrl.text.trim(),
        'calories':  _calCtrl.text.isNotEmpty ? int.tryParse(_calCtrl.text) : null,
        'protein':   _protCtrl.text.isNotEmpty ? double.tryParse(_protCtrl.text) : null,
        'date':      DateFormat('yyyy-MM-dd').format(DateTime.now()),
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
      title: const Text('Log Meal',
        style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // Meal Type Selector
        const _Label('MEAL TYPE'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _mealTypes.map((t) => GestureDetector(
            onTap: () => setState(() => _mealType = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: _mealType == t
                    ? const LinearGradient(colors: [AppColors.purple, AppColors.purpleLight])
                    : null,
                color: _mealType == t ? null : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _mealType == t
                      ? Colors.transparent
                      : AppColors.cardBorder.withOpacity(0.5)),
              ),
              child: Text(t,
                style: TextStyle(
                  color: _mealType == t ? Colors.white : AppColors.subtextMid,
                  fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 22),

        const _Label('FOOD NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: _foodCtrl,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'e.g. Grilled chicken breast'),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Label('CALORIES (kcal)'),
            const SizedBox(height: 8),
            TextField(
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: '350'),
            ),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Label('PROTEIN (g)'),
            const SizedBox(height: 8),
            TextField(
              controller: _protCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: '28'),
            ),
          ])),
        ]),
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
              : const Text('Save Meal'),
        ),
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
