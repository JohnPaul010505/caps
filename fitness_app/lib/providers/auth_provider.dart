import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

// ─── Auth state ────────────────────────────────────────────────────────

class AuthState {
  final User?   user;
  final String? role;    // 'member' | 'trainer' | 'admin'
  final bool    loading;

  const AuthState({this.user, this.role, this.loading = true});

  AuthState copyWith({User? user, String? role, bool? loading}) => AuthState(
    user:    user    ?? this.user,
    role:    role    ?? this.role,
    loading: loading ?? this.loading,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      await _fetchRole(session.user.id);
    } else {
      state = const AuthState(loading: false);
    }

    _client.auth.onAuthStateChange.listen((data) async {
      final u = data.session?.user;
      if (u != null) {
        await _fetchRole(u.id);
      } else {
        state = const AuthState(loading: false);
      }
    });
  }

  Future<void> _fetchRole(String userId) async {
    try {
      final res = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .single();
      state = AuthState(
        user:    _client.auth.currentUser,
        role:    res['role'] as String?,
        loading: false,
      );
    } catch (_) {
      state = AuthState(
        user:    _client.auth.currentUser,
        role:    null,
        loading: false,
      );
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) return 'Invalid credentials.';
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  /// Admin creates a new account for a member
  Future<String?> createMemberAccount(String email, String password, String memberId) async {
    try {
      // Create Supabase auth user
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) return 'Failed to create account.';

      // Link member to new user account
      await _client
          .from('members')
          .update({'user_id': res.user!.id})
          .eq('id', memberId);

      // Create user_roles entry (member)
      await _client.from('user_roles').insert({
        'user_id': res.user!.id,
        'role': 'member',
      });

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AuthState(loading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});