import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/delivery/delivery_providers.dart';
import '../../core/delivery/delivery_service.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../domain/delivery/delivery_intent.dart';
import '../../domain/delivery/phone_number.dart';
import '../../shared/delivery/delivery_labels.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// S35 Texts for one session (UX-PD6, AC-0913, AC-0915, AC-0917): each
/// request a guest made, with the last four digits of the number only, a
/// status pill that never claims more than the provider reported, the
/// timestamped history and the actions that are safe for its state.
class SessionDeliveries extends StatelessWidget {
  const SessionDeliveries({super.key, required this.intents});

  final List<DeliveryIntent> intents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Texts',
          subtitle:
              'What the delivery service and the provider reported. "Sent" '
              'and "Delivered" never mean the guest opened it.',
        ),
        for (final (index, intent) in intents.indexed) ...[
          if (index > 0) const SizedBox(height: PorcelainSpace.md),
          _DeliveryCard(intent: intent),
        ],
      ],
    );
  }
}

class _DeliveryCard extends ConsumerStatefulWidget {
  const _DeliveryCard({required this.intent});

  final DeliveryIntent intent;

  @override
  ConsumerState<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends ConsumerState<_DeliveryCard> {
  String? _busy;

  DeliveryService get _service => ref.read(deliveryServiceProvider);

  Future<void> _run(
    String action,
    Future<void> Function() call,
    String done,
  ) async {
    setState(() => _busy = action);
    try {
      await call();
      if (mounted) {
        PorcelainToast.show(context, done, tone: PorcelainTone.success);
      }
    } on DeliveryActionFailure catch (error) {
      if (mounted) {
        PorcelainToast.show(
          context,
          '${DeliveryLabels.problem(error.code)} (${error.code})',
          tone: PorcelainTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirm,
    required String keep,
    required IconData icon,
  }) async {
    final confirmed = await showPorcelainSheet<bool>(
      context: context,
      title: title,
      body: Text(message),
      actions: (sheet) => [
        PorcelainButton(
          label: keep,
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
        PorcelainButton(
          label: confirm,
          icon: icon,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    );
    return confirmed == true && mounted;
  }

  /// Tries a waiting request now and says what happened.
  Future<void> _tryNow() async {
    final id = widget.intent.id;
    setState(() => _busy = 'try');
    try {
      await _service.tryNow(id);
      final now = await ref.read(deliveryRepositoryProvider).find(id);
      if (!mounted) return;
      final code = now?.lastErrorCode;
      if (now != null && now.state == DeliveryIntentState.queued) {
        PorcelainToast.show(
          context,
          'Still waiting: ${DeliveryLabels.problem(code ?? 'OFFLINE')}',
          tone: PorcelainTone.warning,
        );
      } else {
        PorcelainToast.show(
          context,
          'Handed to the service: ${DeliveryLabels.phase(now?.phase ?? DeliveryPhase.uploading)}.',
          tone: PorcelainTone.success,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _cancel() async {
    final intent = widget.intent;
    if (!await _confirm(
      title: 'Cancel this text?',
      message:
          'It will not be sent and its number is erased from this booth. '
          'The photo stays in the gallery.',
      confirm: 'Cancel text',
      keep: 'Keep it',
      icon: PorcelainIcons.close,
    )) {
      return;
    }
    await _run(
      'cancel',
      () => _service.cancel(intent.id),
      'The text is canceled.',
    );
  }

  Future<void> _revoke() async {
    final intent = widget.intent;
    if (!await _confirm(
      title: 'Turn the link off?',
      message:
          "The guest's link stops working and the copy held by the delivery "
          'service is deleted. A text already sent cannot be taken back. '
          'This cannot be undone.',
      confirm: 'Turn link off',
      keep: 'Keep the link',
      icon: PorcelainIcons.linkOff,
    )) {
      return;
    }
    await _run(
      'revoke',
      () => _service.revoke(intent.id),
      'The link is off and the hosted copy deleted.',
    );
  }

  Future<void> _close() async {
    final intent = widget.intent;
    if (!await _confirm(
      title: 'Close without sending again?',
      message:
          'Use this when the guest got the text, or you decide not to send '
          'it again. It is marked failed and nothing more is sent.',
      confirm: 'Close it',
      keep: 'Not now',
      icon: PorcelainIcons.close,
    )) {
      return;
    }
    await _run(
      'close',
      () => _service.resolve(intent.id, resend: false),
      'Closed. Nothing more will be sent.',
    );
  }

  Future<void> _resend() async {
    final intent = widget.intent;
    if (!await _confirm(
      title: 'Send it again?',
      message:
          'The service could not confirm whether the first text went out. '
          'If it did, the guest gets two texts. Ask the guest first if you '
          'can.',
      confirm: 'Send again',
      keep: 'Not now',
      icon: PorcelainIcons.send,
    )) {
      return;
    }
    await _run(
      'resend',
      () => _service.resolve(intent.id, resend: true),
      'Sent again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final muted = theme.text.bodySmall.copyWith(color: theme.colors.inkMuted);
    final intent = widget.intent;
    final phase = intent.phase;
    final revokedAt = intent.linkRevokedAtUtc;
    final code = intent.lastErrorCode;
    final busy = _busy != null;
    final waiting =
        !intent.finished && intent.state == DeliveryIntentState.queued;
    final cancellable =
        !intent.finished &&
        (intent.remoteJobId == null || phase == DeliveryPhase.uploading);
    final linkLive =
        intent.remoteJobId != null &&
        !intent.gone &&
        revokedAt == null &&
        switch (phase) {
          DeliveryPhase.submitted ||
          DeliveryPhase.sent ||
          DeliveryPhase.delivered ||
          DeliveryPhase.unknown => true,
          _ => false,
        };
    final undecided = phase == DeliveryPhase.unknown && !intent.gone;

    return PorcelainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  PorcelainIcons.textMessage,
                  color: theme.colors.inkMuted,
                  size: 28,
                ),
                const SizedBox(width: PorcelainSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intent.phoneLast4.isEmpty
                            ? 'Number not kept'
                            : maskLast4(intent.phoneLast4),
                        style: theme.text.titleMedium,
                      ),
                      Text(
                        'Asked ${formatTimestamp(intent.createdAtUtc.toLocal())}'
                        ' · link for ${intent.linkDays == 1 ? '1 day' : '${intent.linkDays} days'}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PorcelainSpace.md),
                StatusBadge(
                  label: DeliveryLabels.phase(phase),
                  tone: DeliveryLabels.tone(phase),
                ),
              ],
            ),
          ),
          const SizedBox(height: PorcelainSpace.sm),
          Text(DeliveryLabels.meaning(phase), style: theme.text.bodyMedium),
          if (code != null)
            Text('${DeliveryLabels.problem(code)} ($code)', style: muted),
          if (waiting && intent.retryAtUtc != null)
            Text(
              'Next try ${formatClock(intent.retryAtUtc!.toLocal())}; '
              'dropped at ${formatTimestamp(intent.expiresAtUtc.toLocal())} '
              'if not sent.',
              style: muted,
            ),
          if (revokedAt != null)
            Text(
              'Link turned off ${formatTimestamp(revokedAt.toLocal())}; the '
              'hosted copy is deleted.',
              style: muted,
            ),
          if (intent.history.isNotEmpty) ...[
            const SizedBox(height: PorcelainSpace.sm),
            for (final step in intent.history)
              Text(
                '${formatTimestamp(step.atUtc.toLocal())}  '
                '${step.code == DeliveryIntent.linkRevokedCode ? 'Link turned off' : DeliveryLabels.phase(step.phase)}'
                '${step.code == null || step.code == DeliveryIntent.linkRevokedCode ? '' : ' (${step.code})'}',
                style: muted,
              ),
          ],
          if (waiting || cancellable || linkLive || undecided) ...[
            const SizedBox(height: PorcelainSpace.md),
            Wrap(
              spacing: PorcelainSpace.sm,
              runSpacing: PorcelainSpace.sm,
              children: [
                if (waiting)
                  PorcelainButton(
                    label: 'Try now',
                    icon: PorcelainIcons.retry,
                    size: PorcelainButtonSize.compact,
                    busy: _busy == 'try',
                    onPressed: busy ? null : () => unawaited(_tryNow()),
                  ),
                if (undecided) ...[
                  PorcelainButton(
                    label: 'Close it',
                    icon: PorcelainIcons.close,
                    size: PorcelainButtonSize.compact,
                    busy: _busy == 'close',
                    onPressed: busy ? null : () => unawaited(_close()),
                  ),
                  PorcelainButton(
                    label: 'Send again',
                    icon: PorcelainIcons.send,
                    size: PorcelainButtonSize.compact,
                    busy: _busy == 'resend',
                    onPressed: busy ? null : () => unawaited(_resend()),
                  ),
                ],
                if (cancellable)
                  PorcelainButton(
                    label: 'Cancel text',
                    icon: PorcelainIcons.close,
                    variant: PorcelainButtonVariant.danger,
                    size: PorcelainButtonSize.compact,
                    busy: _busy == 'cancel',
                    onPressed: busy ? null : () => unawaited(_cancel()),
                  ),
                if (linkLive)
                  PorcelainButton(
                    label: 'Turn link off',
                    icon: PorcelainIcons.linkOff,
                    variant: PorcelainButtonVariant.danger,
                    size: PorcelainButtonSize.compact,
                    busy: _busy == 'revoke',
                    onPressed: busy ? null : () => unawaited(_revoke()),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
