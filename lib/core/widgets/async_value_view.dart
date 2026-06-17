import 'package:flutter/material.dart';

import '../error/result.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// Rende un [Resource] scegliendo tra [LoadingView], [ErrorView] e un builder
/// per i dati — centralizza lo switch `loading / error / data`.
class AsyncValueView<T> extends StatelessWidget {
  final Resource<T> resource;
  final Widget Function(T data) onData;
  final VoidCallback? onRetry;

  const AsyncValueView({
    super.key,
    required this.resource,
    required this.onData,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (resource) {
      Loading<T>() => const LoadingView(),
      Failure<T>(:final error) => ErrorView(message: error.message, onRetry: onRetry),
      Success<T>(:final data) => onData(data),
    };
  }
}
