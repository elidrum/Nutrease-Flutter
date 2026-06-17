import 'package:flutter/material.dart';

/// Indicatore di progresso centrato per gli stati di caricamento.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
