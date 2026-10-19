import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/delivery/delivery_providers.dart';
import '../../core/delivery/delivery_service.dart';
import '../../core/delivery/diagnostic_image.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/delivery/delivery_intent.dart';
import '../../domain/delivery/phone_number.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/services/delivery_api.dart';
import '../../shared/delivery/delivery_labels.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// S36 Phone delivery (UX-PD6 booth diagnostics): pairing this booth with
/// the delivery service, what the service says, its limits and background
/// work, the booth's own pause switch, and the latest texts. The booth
/// holds only its own credential (in secure storage); it never sees the
/// messaging provider's keys, and nothing here sends a text.
class DeliverySettings extends ConsumerWidget {
  const DeliverySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(deliveryPairingProvider);
    return switch (pairing) {
      AsyncData(value: null) => const _PairForm(),
      AsyncData(value: final pairing?) => _Paired(pairing: pairing),
      AsyncError() => const PorcelainCard(
        child: Text('Phone delivery settings could not be read.'),
      ),
      _ => const SizedBox(height: 200),
    };
  }
}

/// Pairing: the service address and the single-use code an administrator
/// gives (backend: POST /v1/admin/tenants/{id}/pairing-codes).
class _PairForm extends ConsumerStatefulWidget {
  const _PairForm();

  @override
  ConsumerState<_PairForm> createState() => _PairFormState();
}

class _PairFormState extends ConsumerState<_PairForm> {
  final _address = TextEditingController(text: 'https://');
  final _code = TextEditingController();
  final _name = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(boothProfileProvider).value;
    _name.text = profile?.name ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final address = Uri.tryParse(
      _address.text.trim().replaceAll(RegExp(r'/+$'), ''),
    );
    if (address == null || address.host.isEmpty) {
      setState(
        () => _error = 'Enter the https address your administrator gave you.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(deliveryServiceProvider)
          .pair(
            baseUrl: address,
            code: _code.text,
            boothName: _name.text.trim().isEmpty ? 'Booth' : _name.text.trim(),
          );
      ref.read(deliveryRunnerProvider).checkSoon();
      if (mounted) {
        PorcelainToast.show(
          context,
          'This booth is paired.',
          tone: PorcelainTone.success,
        );
      }
    } on DeliveryApiException catch (error) {
      setState(
        () => _error = switch (error.code) {
          'PAIRING_CODE_INVALID' =>
            "That code isn't valid or has expired. Ask for a new one.",
          'SERVICE_ADDRESS_INVALID' =>
            'Use the https address your administrator gave you.',
          'PAIRING_RATE_LIMITED' => 'Too many tries. Wait ten minutes.',
          _ when error.kind == DeliveryFailureKind.transient =>
            "Can't reach the service. Check this tablet's internet "
                'connection (${error.code}).',
          _ => 'The service refused the pairing (${error.code}).',
        },
      );
    } on Object {
      setState(
        () =>
            _error = "This tablet's secure storage could not keep the pairing.",
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Pair this booth',
          subtitle:
              'Texting photos needs the delivery service your business runs. '
              'Until this booth is paired and the service is ready, guests '
              'never see texting.',
        ),
        PorcelainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PorcelainTextField(
                label: 'Service address',
                controller: _address,
                hint: 'https://photos.your-business.com',
                keyboardType: TextInputType.url,
                enabled: !_busy,
              ),
              const SizedBox(height: PorcelainSpace.md),
              PorcelainTextField(
                label: 'Pairing code',
                controller: _code,
                hint: 'XXXX-XXXX-XXXX',
                helper: 'Single use, valid for 30 minutes.',
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z -]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                enabled: !_busy,
              ),
              const SizedBox(height: PorcelainSpace.md),
              PorcelainTextField(
                label: 'Name for this booth',
                controller: _name,
                maxLength: 40,
                enabled: !_busy,
              ),
              if (_error case final error?) ...[
                const SizedBox(height: PorcelainSpace.sm),
                StatusBadge(label: error, tone: PorcelainTone.danger),
              ],
              const SizedBox(height: PorcelainSpace.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: PorcelainButton(
                  label: 'Pair',
                  icon: PorcelainIcons.pairing,
                  variant: PorcelainButtonVariant.primary,
                  busy: _busy,
                  onPressed: _busy ? null : () => unawaited(_pair()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.md),
        const _Note(
          'The booth keeps only its own credential, in this tablet\'s secure '
          'storage. Messaging and storage keys stay with the service.',
        ),
      ],
    );
  }
}

class _Paired extends ConsumerWidget {
  const _Paired({required this.pairing});

  final DeliveryPairing pairing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(deliveryLinkProvider);
    final capabilities = pairing.capabilities;
    final service = ref.read(deliveryServiceProvider);
    final ready = capabilities?.ready ?? false;
    final status = pairing.paused
        ? ('Paused on this booth', PorcelainTone.warning)
        : link.offline
        ? ('Offline', PorcelainTone.warning)
        : capabilities == null
        ? ('Not checked yet', PorcelainTone.neutral)
        : ready
        ? ('Ready', PorcelainTone.success)
        : ('Not ready', PorcelainTone.warning);

    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        if (context.mounted) {
          PorcelainToast.show(context, done, tone: PorcelainTone.success);
        }
      } on DeliveryApiException catch (error) {
        if (context.mounted) {
          PorcelainToast.show(
            context,
            '${DeliveryLabels.problem(error.code)} (${error.code})',
            tone: PorcelainTone.danger,
          );
        }
      } on DeliveryActionFailure catch (error) {
        if (context.mounted) {
          PorcelainToast.show(
            context,
            '${DeliveryLabels.problem(error.code)} (${error.code})',
            tone: PorcelainTone.danger,
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Delivery service',
          subtitle:
              'Paired ${formatDay(pairing.pairedAtUtc.toLocal())} as '
              '"${pairing.boothName}".',
          trailing: StatusBadge(label: status.$1, tone: status.$2),
        ),
        PorcelainCard(
          padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.sm),
          child: Column(
            children: [
              PorcelainListRow(
                icon: PorcelainIcons.link,
                title: 'Service',
                subtitle: pairing.baseUrl.host,
                showChevron: false,
              ),
              PorcelainListRow(
                icon: link.offline
                    ? PorcelainIcons.offline
                    : PorcelainIcons.online,
                title: 'Connection',
                subtitle: link.offline
                    ? '${DeliveryLabels.problem(link.lastCode ?? 'OFFLINE')} '
                          'Since ${formatClock(link.failingSinceUtc!.toLocal())}.'
                    : link.checkedAtUtc == null
                    ? 'Not contacted since the app started.'
                    : 'Reached at ${formatClock(link.checkedAtUtc!.toLocal())}.',
                showChevron: false,
              ),
              PorcelainListRow(
                icon: PorcelainIcons.textMessage,
                title: 'Sending',
                subtitle: capabilities == null
                    ? 'Check the service to see if it can send.'
                    : ready
                    ? 'Ready: the sender is registered, the legal review is '
                          'recorded and sending is on.'
                    : capabilities.reasons.map(DeliveryLabels.reason).join(' '),
                showChevron: false,
                trailing: StatusBadge(
                  label: ready ? 'Ready' : 'Not ready',
                  tone: ready ? PorcelainTone.success : PorcelainTone.warning,
                ),
              ),
              if (capabilities != null) ...[
                PorcelainListRow(
                  icon: PorcelainIcons.preflight,
                  title: 'Texts left today',
                  subtitle:
                      '${capabilities.boothDailyRemaining} for this booth, '
                      '${capabilities.tenantDailyRemaining} for the business.',
                  showChevron: false,
                ),
                PorcelainListRow(
                  icon: PorcelainIcons.info,
                  title: 'This month (estimate)',
                  subtitle:
                      '${DeliveryLabels.dollars(capabilities.monthEstimatedCents)} of '
                      '${DeliveryLabels.dollars(capabilities.monthlyBudgetCents)}. '
                      'Estimates only; the provider bills the actual cost.',
                  showChevron: false,
                ),
                PorcelainListRow(
                  icon: PorcelainIcons.refresh,
                  title: 'Service checks',
                  subtitle: [
                    _since('Status reports', capabilities.statusWebhookAtUtc),
                    _since('Sending worker', capabilities.dispatchWorkerAtUtc),
                    _since('Clean-up', capabilities.retentionWorkerAtUtc),
                  ].join(' · '),
                  showChevron: false,
                ),
              ],
              if (pairing.checkedAtUtc case final checked?)
                PorcelainListRow(
                  icon: PorcelainIcons.pending,
                  title: 'Last checked',
                  subtitle:
                      '${formatDay(checked.toLocal())} '
                      '${formatClock(checked.toLocal())}'
                      '${capabilities?.environment == 'staging' ? ' · staging service (test numbers only)' : ''}',
                  showChevron: false,
                ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.md),
        Wrap(
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.sm,
          children: [
            PorcelainButton(
              label: 'Check now',
              icon: PorcelainIcons.refresh,
              onPressed: () =>
                  unawaited(run(() async => service.check(), 'Checked.')),
            ),
            PorcelainButton(
              label: 'Test an upload',
              icon: PorcelainIcons.upload,
              onPressed: () => unawaited(
                run(
                  () async => service.uploadTest(diagnosticJpeg),
                  'Upload works. Nothing was stored or sent.',
                ),
              ),
            ),
            PorcelainButton(
              label: pairing.paused ? 'Resume texting' : 'Pause texting',
              icon: PorcelainIcons.pause,
              onPressed: () => unawaited(
                run(
                  () => service.setPaused(!pairing.paused),
                  pairing.paused
                      ? 'Texting resumed.'
                      : 'Texting paused on this booth.',
                ),
              ),
            ),
            PorcelainButton(
              label: 'Export diagnostics',
              icon: PorcelainIcons.export,
              onPressed: () => unawaited(_export(context, ref, pairing)),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xs),
        const _Note(
          'Pause stops new requests and sending from this booth at once. To '
          'stop every booth, switch sending off at the service. Test texts are '
          'sent from the staging service to approved test phones only.',
        ),
        const SizedBox(height: PorcelainSpace.xxl),
        const _RecentTexts(),
        const SizedBox(height: PorcelainSpace.xxl),
        SectionHeader(
          title: 'Pairing',
          subtitle: 'Booth ID ${pairing.boothId.substring(0, 8)}…',
        ),
        Wrap(
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.sm,
          children: [
            PorcelainButton(
              label: 'Renew credential',
              icon: PorcelainIcons.pairing,
              onPressed: () => unawaited(
                run(
                  service.rotateCredential,
                  'The booth has a new credential.',
                ),
              ),
            ),
            PorcelainButton(
              label: 'Unpair',
              icon: PorcelainIcons.linkOff,
              variant: PorcelainButtonVariant.danger,
              onPressed: () => unawaited(_unpair(context, ref)),
            ),
          ],
        ),
      ],
    );
  }

  static String _since(String what, DateTime? at) =>
      at == null ? '$what: never' : '$what ${formatClock(at.toLocal())}';

  Future<void> _unpair(BuildContext context, WidgetRef ref) async {
    final confirmed = await showPorcelainSheet<bool>(
      context: context,
      title: 'Unpair this booth?',
      body: const Text(
        'Guests will no longer be offered texting. Requests still waiting on '
        'this booth cannot be sent and expire within 24 hours. Texts already '
        'sent are not affected. To pair again you need a new code.',
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Keep pairing',
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
        PorcelainButton(
          label: 'Unpair',
          icon: PorcelainIcons.linkOff,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;
    await ref.read(deliveryServiceProvider).unpair();
    if (context.mounted) {
      PorcelainToast.show(context, 'This booth is no longer paired.');
    }
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    DeliveryPairing pairing,
  ) async {
    // The share sheet anchors to this pane (iPad needs an anchor).
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final repository = ref.read(deliveryRepositoryProvider);
    final link = ref.read(deliveryLinkProvider);
    final counts = await repository.counts();
    final recent = await repository.watchRecent(limit: 100).first;
    final now = ref.read(clockProvider).now().toUtc();
    final text = [
      'Porcelain Photo Booth: phone delivery diagnostics (redacted)',
      'Generated: ${now.toIso8601String()}',
      'Service: ${pairing.baseUrl.host}',
      'Booth: ${pairing.boothId}',
      'Paused: ${pairing.paused}',
      'Ready: ${pairing.capabilities?.ready} ${pairing.capabilities?.reasons ?? const []}',
      'Environment: ${pairing.capabilities?.environment}',
      'Last checked: ${pairing.checkedAtUtc?.toIso8601String()}',
      'Connection: ${link.offline ? 'offline since ${link.failingSinceUtc!.toIso8601String()} (${link.lastCode})' : 'ok'}',
      'Counts: ${{for (final phase in DeliveryPhase.values)
        if (counts.of(phase) > 0) phase.name: counts.of(phase)}}',
      '',
      'Latest requests (no numbers, no links):',
      for (final intent in recent)
        '${intent.createdAtUtc.toIso8601String()} ${intent.phase.name} '
            'attempts=${intent.attemptCount} code=${intent.lastErrorCode ?? '-'} '
            'event=${intent.eventId.substring(0, 8)} '
            'remote=${intent.remoteJobId == null ? '-' : intent.remoteJobId!.substring(0, 8)}',
    ].join('\n');
    try {
      await ref
          .read(operatorFilesProvider)
          .share(
            Uint8List.fromList(utf8.encode(text)),
            fileName: 'delivery-diagnostics.txt',
            mimeType: 'text/plain',
            anchor: (left: origin.dx, top: origin.dy, width: 1, height: 1),
          );
    } on Exception {
      if (context.mounted) {
        PorcelainToast.show(
          context,
          'The diagnostics could not be shared.',
          tone: PorcelainTone.danger,
        );
      }
    }
  }
}

/// The latest texts across events (UX-PD6 overview): masked numbers only,
/// each opening its session for details and actions.
class _RecentTexts extends ConsumerWidget {
  const _RecentTexts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentDeliveriesProvider(null));
    final counts = ref.watch(deliveryCountsProvider(null)).value;
    final events = {
      for (final event
          in ref.watch(eventsProvider).value ?? const <BoothEvent>[])
        event.id: event.title,
    };
    final intents = recent.value ?? const <DeliveryIntent>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent texts',
          subtitle: counts == null || counts.total == 0
              ? 'No texts requested on this booth yet.'
              : '${counts.total} requested · ${counts.submitted} reached the '
                    'provider · ${counts.of(DeliveryPhase.delivered)} confirmed '
                    'delivered',
        ),
        if (intents.isNotEmpty)
          PorcelainCard(
            padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.sm),
            child: Column(
              children: [
                for (final intent in intents.take(20))
                  PorcelainListRow(
                    icon: PorcelainIcons.textMessage,
                    title:
                        '${intent.phoneLast4.isEmpty ? 'Number not kept' : maskLast4(intent.phoneLast4)} · '
                        '${events[intent.eventId] ?? 'Deleted event'}',
                    subtitle:
                        '${formatDay(intent.createdAtUtc.toLocal())} '
                        '${formatClock(intent.createdAtUtc.toLocal())}'
                        '${intent.lastErrorCode == null ? '' : ' · ${DeliveryLabels.problem(intent.lastErrorCode!)}'}',
                    trailing: StatusBadge(
                      label: DeliveryLabels.phase(intent.phase),
                      tone: DeliveryLabels.tone(intent.phase),
                    ),
                    onPressed: () =>
                        context.go(RoutePaths.gallerySession(intent.sessionId)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Text(
      text,
      style: theme.text.bodySmall.copyWith(color: theme.colors.inkMuted),
    );
  }
}
