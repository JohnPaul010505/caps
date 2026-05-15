import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading  = false;
  bool _showPw   = false;
  String? _error;

  // 0 = Member, 1 = Trainer
  int _selectedRole = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _selectedRole = _tabCtrl.index;
          _error = null;
          _emailCtrl.clear();
          _passwordCtrl.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final err = await ref.read(authProvider.notifier).signIn(email, password);

    if (!mounted) return;

    if (err != null) {
      setState(() { _error = err; _loading = false; });
      return;
    }

    // After login, check the role matches the selected tab
    final role = ref.read(authProvider).role;
    final expectedRole = _selectedRole == 0 ? 'member' : 'trainer';

    if (role != expectedRole) {
      // Wrong tab selected — still works, router handles redirect
      // But show a helpful note
      setState(() { _loading = false; });
    }
    // Router redirect handles navigation automatically
  }

  @override
  Widget build(BuildContext context) {
    final isMember = _selectedRole == 0;
    final accentColor = isMember ? AppColors.purple : AppColors.green;
    final roleLabel   = isMember ? 'Member' : 'Trainer';
    final roleHint    = isMember ? 'member@email.com' : 'trainer@email.com';
    final roleIcon    = isMember ? '🏋️' : '💪';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── Logo ──────────────────────────────────────────
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.purpleLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.4),
                        blurRadius: 24, offset: const Offset(0, 8),
                      )],
                    ),
                    alignment: Alignment.center,
                    child: const Text('⚡', style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(height: 18),
                  const Text('FitTrack',
                      style: TextStyle(
                        color: AppColors.text, fontSize: 26,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 6),
                  const Text('Fitness Management System',
                      style: TextStyle(color: AppColors.subtext, fontSize: 13)),

                  const SizedBox(height: 32),

                  // ── Role Tabs ─────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.cardBorder.withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabCtrl,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMember
                              ? [AppColors.purple, AppColors.purpleLight]
                              : [AppColors.green, const Color(0xFF16A34A)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        )],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.subtext,
                      labelStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      tabs: const [
                        Tab(text: '🏋️  Member'),
                        Tab(text: '💪  Trainer'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Login Card ────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.2)),
                      boxShadow: [BoxShadow(
                        color: accentColor.withValues(alpha: 0.06),
                        blurRadius: 20, spreadRadius: 2,
                      )],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Role label
                        Row(children: [
                          Text(roleIcon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text('$roleLabel Login',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                        ]),
                        const SizedBox(height: 20),

                        // Error banner
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!,
                                  style: const TextStyle(
                                      color: Color(0xFFF87171), fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        _label('EMAIL'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_loading,
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: roleHint,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: accentColor, width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _label('PASSWORD'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: !_showPw,
                          enabled: !_loading,
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: accentColor, width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showPw = !_showPw),
                              icon: Icon(
                                  _showPw
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.subtext, size: 18),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            shadowColor: accentColor.withValues(alpha: 0.4),
                            elevation: 6,
                          ),
                          child: _loading
                              ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : Text('Sign In as $roleLabel'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    isMember
                        ? 'Use the credentials given by your gym admin'
                        : 'Use the credentials given by the gym admin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.subtext, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
        color: AppColors.subtext, fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 0.5,
      ));
}