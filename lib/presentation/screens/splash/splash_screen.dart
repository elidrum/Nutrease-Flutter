import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../../../domain/repository/auth_repository.dart';
import 'root_view_model.dart';

/// Splash che risolve la rotta iniziale dallo stato di sessione e naviga.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RootViewModel>(
      create: (ctx) =>
          RootViewModel(ctx.read<AuthRepository>())..resolveStartDestination(),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final target = context.watch<RootViewModel>().state.targetRoute;
    if (target != null && !_navigated) {
      _navigated = true;
      // Navigo dopo il frame corrente per non fare routing durante il build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(target);
      });
    }
    return const Scaffold(body: LoadingView());
  }
}
