import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/porcelain_icons.dart';
import '../core/routing/route_paths.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/porcelain_button.dart';

/// Fallback for unknown locations.
///
/// Deliberately shows no route, error or exception text: raw failure details
/// must never reach a guest (CLAUDE.md, Porcelain UX). Once Booth Mode
/// exists (M07) a guest's fallback must stay inside the guest subtree.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: EmptyState(
              icon: PorcelainIcons.info,
              title: "This page isn't available",
              message: 'Return to the Studio to carry on.',
              actions: [
                PorcelainButton(
                  label: 'Return to Studio',
                  variant: PorcelainButtonVariant.primary,
                  onPressed: () => context.go(RoutePaths.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
