import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/fields/ui/home_dashboard.dart';
import '../../features/fields/ui/add_field_screen.dart';
import '../../features/fields/ui/field_detail_screen.dart';
import '../../features/fields/ui/map_picker_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authNotifierProvider).asData?.value;
    if (authState == null) return null; // App is initializing

    final isLoggedIn = authState.isAuthenticated;
    final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/';
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeDashboard(),
      ),
      GoRoute(
        path: '/add-field',
        builder: (context, state) => const AddFieldScreen(),
      ),
      GoRoute(
        path: '/field/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FieldDetailScreen(fieldId: id);
        },
      ),
      GoRoute(
        path: '/map-picker',
        builder: (context, state) => const MapPickerScreen(),
      ),
    ],
  );
});
