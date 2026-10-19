import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/delivery/delivery_providers.dart';
import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/di/service_providers.dart';
import '../../../domain/delivery/consent.dart';
import '../../../domain/delivery/delivery_settings.dart';
import '../../../domain/repositories/delivery_repository.dart';
import '../../../shared/delivery/delivery_labels.dart';
import '../../../shared/widgets/porcelain_button.dart';
import '../../../shared/widgets/porcelain_stepper.dart';
import '../../../shared/widgets/porcelain_switch.dart';
import '../../../shared/widgets/porcelain_toast.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tone.dart';
import 'editor_parts.dart';

/// S34 Phone delivery for this event (UX-PD5, AC-0901): off by default;
/// it can be turned on only when this booth is paired and the service says
/// sending is ready. The mode and region are fixed for release 1; the link
/// life, the event's send limit and waiting while offline are the
/// operator's, with the estimated cost of the limit.
class DeliveryTab extends ConsumerWidget {
  const DeliveryTab({super.key, required this.tab});

  final EditorTabContext tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = tab.event;
    final settings = event.delivery;
    final pairing = ref.watch(deliveryPairingProvider).value;
    final capabilities = pairing?.capabilities;
    final ready =
        pairing != null && !pairing.paused && (capabilities?.ready ?? false);
    final String? enableReason;
    if (tab.readOnlyReason case final reason?) {
      enableReason = reason;
    } else if (pairing == null) {
      enableReason = 'Pair this booth first: Settings > Phone delivery.';
    } else if (pairing.paused) {
      enableReason =
          'Texting is paused on this booth: Settings > Phone delivery.';
    } else if (capabilities == null) {
      enableReason = 'Check the service first: Settings > Phone delivery.';
    } else if (!capabilities.ready) {
      enableReason = DeliveryLabels.reason(
        capabilities.reasons.firstOrNull ?? '',
      );
    } else {
      enableReason = null;
    }
    // Turning texting off is always possible.
    final canToggle = settings.enabled
        ? tab.readOnlyReason == null
        : enableReason == null;
    final linkMax = math.max(
      1,
      capabilities?.linkDaysMax ?? EventDeliverySettings.defaultLinkDays,
    );
    final limitMax = math.max(
      10,
      math.min(
        EventDeliverySettings.maxSendLimit,
        (capabilities?.eventSendLimitMax ?? 0) > 0
            ? capabilities!.eventSendLimitMax
            : EventDeliverySettings.maxSendLimit,
      ),
    );
    final costEach = capabilities?.estimatedCostMillicents ?? 3200;
    final estimateCents = (settings.sendLimit * costEach / 1000).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'Text photos to guests',
          subtitle:
              'After their photo is saved, guests may ask for one text with '
              'a preview and a private link to the full-size photo. Off '
              'unless you turn it on.',
          trailing: _ReadinessBadge(pairing: pairing),
          children: [
            PorcelainSwitchRow(
              title: 'Offer "Text my photos"',
              subtitle: settings.enabled && !ready
                  ? "On, but guests won't see it until the service is ready."
                  : 'Guests choose; finishing never needs a text.',
              icon: PorcelainIcons.textMessage,
              value: settings.enabled,
              disabledReason: canToggle ? null : enableReason,
              onChanged: canToggle
                  ? (value) => tab.onChanged(
                      event.copyWith(
                        delivery: settings.copyWith(enabled: value),
                      ),
                    )
                  : null,
            ),
            const EditorSetting(
              title: 'What guests get',
              description:
                  'One picture message (MMS) with a small preview and a private '
                  'link to the full-quality finished photo. Fixed in this '
                  'release.',
              control: StatusBadge(
                label: 'MMS + private link',
                icon: PorcelainIcons.link,
              ),
            ),
            const EditorSetting(
              title: 'Numbers',
              description: 'United States mobile numbers only (+1).',
              control: StatusBadge(
                label: 'US only',
                icon: PorcelainIcons.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Link and limit',
          subtitle:
              'How long the download link works, and how many texts '
              'this event may send.',
          children: [
            EditorSetting(
              title: 'Link works for',
              description:
                  'The service allows up to $linkMax '
                  '${linkMax == 1 ? 'day' : 'days'}.',
              control: PorcelainStepper(
                label: 'Link works for',
                value: math.min(settings.linkDays, linkMax),
                min: 1,
                max: linkMax,
                formatValue: (days) => days == 1 ? '1 day' : '$days days',
                decreaseLabel: 'Fewer days',
                increaseLabel: 'More days',
                minimumReason: 'A link works for at least a day.',
                maximumReason: capabilities == null
                    ? 'Check the service to see how long links may last.'
                    : 'The service allows up to $linkMax '
                          '${linkMax == 1 ? 'day' : 'days'}.',
                disabledReason: tab.readOnlyReason,
                onChanged: tab.edit(
                  (days) => event.copyWith(
                    delivery: settings.copyWith(linkDays: days),
                  ),
                ),
              ),
            ),
            EditorSetting(
              title: 'Most texts for this event',
              description:
                  'Up to about ${DeliveryLabels.dollars(estimateCents)} '
                  'at about ${(costEach / 1000).toStringAsFixed(1)}¢ a text. '
                  'An estimate: carrier fees, number rental, registration and '
                  'taxes are billed separately.',
              control: PorcelainStepper(
                label: 'Most texts for this event',
                value: math.min(settings.sendLimit, limitMax),
                min: 10,
                max: limitMax,
                step: 10,
                decreaseLabel: 'Ten fewer',
                increaseLabel: 'Ten more',
                minimumReason: 'At least ten texts.',
                maximumReason: 'The most this event can allow.',
                disabledReason: tab.readOnlyReason,
                onChanged: tab.edit(
                  (limit) => event.copyWith(
                    delivery: settings.copyWith(sendLimit: limit),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'When the booth is offline',
          children: [
            PorcelainSwitchRow(
              title: 'Take requests while offline',
              subtitle:
                  'Kept for up to 24 hours while the app is open, sent if the '
                  'booth reconnects; guests are told it may not arrive. Off: '
                  'texting is only offered while connected.',
              icon: PorcelainIcons.offline,
              value: settings.offlineQueue,
              disabledReason: tab.readOnlyReason,
              onChanged: tab.edit(
                (value) => event.copyWith(
                  delivery: settings.copyWith(offlineQueue: value),
                ),
              ),
            ),
            const EditorNote(
              icon: PorcelainIcons.info,
              text:
                  'Nothing is sent while the app is closed or in the '
                  'background. A request not sent within 24 hours is dropped '
                  'and its number erased; the photo stays in the gallery.',
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        _ConsentCard(tab: tab, pairing: pairing),
      ],
    );
  }
}

class _ReadinessBadge extends StatelessWidget {
  const _ReadinessBadge({required this.pairing});

  final DeliveryPairing? pairing;

  @override
  Widget build(BuildContext context) {
    final pairing = this.pairing;
    if (pairing == null) {
      return const StatusBadge(
        label: 'Not paired',
        icon: PorcelainIcons.pairing,
      );
    }
    if (pairing.paused) {
      return const StatusBadge(
        label: 'Paused',
        tone: PorcelainTone.warning,
        icon: PorcelainIcons.pause,
      );
    }
    final ready = pairing.capabilities?.ready ?? false;
    return StatusBadge(
      label: ready ? 'Service ready' : 'Service not ready',
      tone: ready ? PorcelainTone.success : PorcelainTone.warning,
    );
  }
}

/// What guests agree to, exactly as shown, with its version and digest,
/// and an export for the sender registration and legal review.
class _ConsentCard extends ConsumerWidget {
  const _ConsentCard({required this.tab, required this.pairing});

  final EditorTabContext tab;
  final DeliveryPairing? pairing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final capabilities = pairing?.capabilities;
    final brand =
        capabilities?.brandName ?? pairing?.brandName ?? 'Your business';
    final consent = ConsentText(
      brand: brand,
      linkDays: tab.event.delivery.linkDays,
    );
    return EditorCard(
      title: 'What guests agree to',
      subtitle:
          'Shown next to an unchecked box. A draft for your legal '
          'review and sender registration.',
      children: [
        Text(consent.text, style: theme.text.bodyLarge),
        Text(
          'Version ${ConsentText.version} · fingerprint ${consent.digest.substring(0, 12)}',
          style: theme.text.bodySmall.copyWith(color: theme.colors.inkMuted),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Builder(
            builder: (buttonContext) => PorcelainButton(
              label: 'Export consent proof',
              icon: PorcelainIcons.export,
              onPressed: () async {
                final box = buttonContext.findRenderObject() as RenderBox?;
                final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                final size = box?.size ?? Size.zero;
                final text = DeliveryLabels.consentProof(
                  brand: brand,
                  eventName: tab.event.title,
                  linkDays: tab.event.delivery.linkDays,
                  privacyUrl:
                      capabilities?.privacyUrl ?? 'https://<your privacy page>',
                  termsUrl:
                      capabilities?.termsUrl ?? 'https://<your terms page>',
                  supportContact:
                      capabilities?.supportContact ?? '<your support contact>',
                );
                try {
                  await ref
                      .read(operatorFilesProvider)
                      .share(
                        Uint8List.fromList(utf8.encode(text)),
                        fileName: 'consent-proof-${ConsentText.version}.txt',
                        mimeType: 'text/plain',
                        anchor: (
                          left: origin.dx,
                          top: origin.dy,
                          width: size.width,
                          height: size.height,
                        ),
                      );
                } on Exception {
                  if (context.mounted) {
                    PorcelainToast.show(
                      context,
                      'The consent proof could not be shared.',
                      tone: PorcelainTone.danger,
                    );
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
