import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/route_paths.dart';

/// Fallback for unknown locations.
///
/// Deliberately shows no route, error or exception text: raw failure details
/// must never reach a guest (CLAUDE.md, Porcelain UX).
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    "This page isn't available",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(RoutePaths.home),
                  child: const Text('Return to start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
