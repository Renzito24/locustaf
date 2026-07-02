import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/authentication/application/auth_state_listenable.dart';

class AppRouter {
  static final _auth = AuthStateListenable();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _auth,

    redirect: (context, state) {
      final loggedIn = _auth.isLoggedIn;

      final goingToLogin = state.matchedLocation == '/login';
      final goingToSplash = state.matchedLocation == '/';

      // ❌ no logueado → login
      if (!loggedIn) {
        return goingToLogin ? null : '/login';
      }

      // ✔ logueado → evitar login/splash
      if (loggedIn && (goingToLogin || goingToSplash)) {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}