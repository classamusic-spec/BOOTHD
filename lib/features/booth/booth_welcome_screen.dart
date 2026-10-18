import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_event.dart';
import '../../shared/guest/event_welcome_copy.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/widgets/porcelain_spinner.dart';
import '../../shared/widgets/porcelain_toast.dart';
import 'booth_event_theme.dart';
import 'hidden_operator_exit.dart';

/// Booth Mode's guest welcome (S20) for the running event, in the event's
/// theme ([BoothEventTheme]). Guest sessions arrive in M07: until then
/// Start says, in guest-safe words, that the booth is not ready, and
/// nothing else happens. The only other way off this screen is the
/// operator's hidden hold.
class BoothWelcomeScreen extends ConsumerWidget {
  const BoothWelcomeScreen({super.key});

  static const notReadyMessage =
      "The photo booth isn't quite ready yet. Please ask the event host.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(accessControllerProvider).boothEventId;
    final event = eventId == null
        ? const AsyncData<BoothEvent?>(null)
        : ref.watch(eventProvider(eventId));

    final Widget guest = switch (event) {
      AsyncData(value: final event?) => _Welcome(event: event),
      AsyncLoading() => const _GuestWaiting(),
      // A missing or unreadable event: a calm notice, no details.
      _ => const _GuestNotice(message: notReadyMessage),
    };

    // System back does nothing here: there is nowhere for a guest to go.
    return BoothEventTheme(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: guest),
              HiddenOperatorExit(
                onTriggered: () => context.go(RoutePaths.boothOperator),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.event});

  final BoothEvent event;

  @override
  Widget build(BuildContext context) => GuestWelcome(
    copy: welcomeCopyFor(event),
    onStart: () => PorcelainToast.show(
      context,
      BoothWelcomeScreen.notReadyMessage,
      icon: PorcelainIcons.info,
    ),
  );
}

class _GuestWaiting extends StatelessWidget {
  const _GuestWaiting();

  @override
  Widget build(BuildContext context) => GuestBackdrop(
    child: Center(
      child: PorcelainSpinner(
        color: context.porcelain.colors.accentIcon,
        size: 32,
      ),
    ),
  );
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return GuestBackdrop(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PorcelainSpace.huge),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.text.guestBody,
          ),
        ),
      ),
    );
  }
}
