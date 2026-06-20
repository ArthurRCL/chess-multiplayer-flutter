import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/storage/secure_storage.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cria o container do Riverpod para ler o estado de auth antes de montar
  final container = ProviderContainer();
  final storage = container.read(secureStorageProvider);
  final loggedIn = await storage.isLoggedIn();
  container.read(isLoggedInProvider.notifier).state = loggedIn;

  runApp(UncontrolledProviderScope(
    container: container,
    child: const XadrezApp(),
  ));
}

class XadrezApp extends ConsumerWidget {
  const XadrezApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Xadrez Online',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.woodTheme,
      routerConfig: router,
    );
  }
}
