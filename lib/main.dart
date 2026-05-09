import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: XadrezApp()));
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
