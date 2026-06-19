import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/historico_screen.dart';
import '../../features/home/themes_screen.dart';
import '../../features/partida/partida_screen.dart';

/// Rota pendente para redirecionamento pós-login.
/// Guarda a URL que o usuário tentou acessar antes de ser mandado para /login.
final pendingRedirectProvider = StateProvider<String?>((ref) => null);

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final loggedIn = isLoggedIn.valueOrNull ?? false;
      final currentPath = state.uri.toString();
      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !onAuthRoute) {
        // Salva a rota que o usuário tentou acessar
        ref.read(pendingRedirectProvider.notifier).state = currentPath;
        return '/login';
      }
      if (loggedIn && onAuthRoute) {
        // Após login, redireciona para a rota pendente (ou /home)
        final pending = ref.read(pendingRedirectProvider);
        ref.read(pendingRedirectProvider.notifier).state = null;
        return pending ?? '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/historico',
        name: 'historico',
        builder: (context, state) => const HistoricoScreen(),
      ),
      GoRoute(
        path: '/partida/:id',
        name: 'partida',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PartidaScreen(partidaId: id);
        },
      ),
      GoRoute(
        path: '/temas',
        name: 'temas',
        builder: (context, state) => const ThemesScreen(),
      ),
    ],
  );
});

/// Inicializa o listener de deep links.
/// Captura: xadrezapp://partida/{UUID}
void initDeepLinks(BuildContext context) {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'xadrezapp' && uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] == 'partida') {
        final id = uri.pathSegments[1];
        if (context.mounted) {
          context.go('/partida/$id');
        }
      }
    }
  });
}
