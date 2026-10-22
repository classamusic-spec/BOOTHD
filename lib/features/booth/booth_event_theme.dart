import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/experience/guest_theme.dart';
import '../../domain/experience/experience_registry.dart';

/// Booth Mode wears the running event's guest experience on every screen
/// (EP06): its colours, type and decorations on the guest welcome and the
/// operator's PIN alike, so a look chosen for a venue never flashes to
/// another mid-event. Sessions show their own frozen copy of it.
class BoothEventTheme extends ConsumerWidget {
  const BoothEventTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(accessControllerProvider).boothEventId;
    final event = eventId == null
        ? null
        : ref.watch(eventProvider(eventId)).value;
    if (event == null) return child;
    final experience = ExperienceRegistry.bundled.resolve(event.experience);
    return GuestExperienceScope(experience: experience, child: child);
  }
}
