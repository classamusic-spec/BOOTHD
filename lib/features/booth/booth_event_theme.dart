import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/design_system/porcelain_theme_data.dart';
import '../../domain/experience/experience_registry.dart';

/// Booth Mode wears the running event's guest look, when it has one, on every
/// screen: the guest welcome and the operator's PIN alike, so a theme
/// chosen for a dim venue never flashes to a bright one mid-event.
class BoothEventTheme extends ConsumerWidget {
  const BoothEventTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(accessControllerProvider).boothEventId;
    final experience = eventId == null
        ? null
        : ref.watch(eventProvider(eventId)).value?.experience;
    final override = experience == null
        ? null
        : ExperienceRegistry.legacyAppearance(experience);
    if (override == null) return child;
    return Theme(
      data: porcelainThemeData(
        override,
        highContrast: context.porcelain.highContrast,
      ),
      child: child,
    );
  }
}
