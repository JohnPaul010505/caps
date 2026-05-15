import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/trainer/trainer_home_screen.dart';
import '../screens/trainer/member_detail_screen.dart';
import '../screens/member/member_home_screen.dart';
import '../screens/member/progress_screen.dart';
import '../screens/member/chat_screen.dart';
import '../screens/member/log_meal_screen.dart';
import '../screens/member/log_workout_screen.dart';
import '../screens/shared/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Always allow splash through — no redirect
      if (loc == '/splash') return null;

      // While auth is loading, hold on login (not splash, avoids flicker)
      if (auth.loading) return '/login';

      final loggedIn = auth.user != null;
      final onLogin  = loc == '/login';

      // Not logged in → send to login
      if (!loggedIn) return onLogin ? null : '/login';

      // Logged in but sitting on login → redirect by role
      if (onLogin) {
        switch (auth.role) {
          case 'trainer':
            return '/trainer';
          case 'member':
            return '/member';
          default:
            return '/member';
        }
      }

      // Role-based route protection
      if (auth.role == 'member' && loc.startsWith('/trainer')) {
        return '/member';
      }
      if (auth.role == 'trainer' && loc.startsWith('/member')) {
        return '/trainer';
      }

      return null;
    },
    routes: [

      // ── Splash ────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Trainer routes ────────────────────────────────────────────────
      GoRoute(
        path: '/trainer',
        builder: (_, __) => const TrainerHomeScreen(),
        routes: [
          GoRoute(
            path: 'member/:id',
            builder: (_, state) => MemberDetailScreen(
              memberId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ── Member routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/member',
        builder: (_, __) => const MemberHomeScreen(),
        routes: [
          GoRoute(
            path: 'progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: 'chat',
            builder: (_, __) => const ChatScreen(),
          ),
          GoRoute(
            path: 'log-meal',
            builder: (_, __) => const LogMealScreen(),
          ),
          GoRoute(
            path: 'log-workout',
            builder: (_, __) => const LogWorkoutScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Shared profile ────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  );
});