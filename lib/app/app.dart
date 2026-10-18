import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Root widget: theme and router only.
class PorcelainApp extends ConsumerWidget {
  const PorcelainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Porcelain Photo Booth',
      theme: ThemeData(
        // Interim seed taken from the proposed Porcelain accent (UX-01). The
        // M02 semantic token system replaces this; add no colours here.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAF885E)),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
