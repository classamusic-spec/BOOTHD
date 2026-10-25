import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/booth/booth_providers.dart';
import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_motion.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/experience/guest_theme.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/templates/starter_designs.dart';
import '../../../core/templates/template_thumbnails.dart';
import '../../../domain/experience/experience_pack.dart';
import '../../../domain/experience/experience_registry.dart';
import '../../../domain/models/booth_event.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/repositories/template_store.dart';
import '../../../domain/services/event_service.dart';
import '../../../domain/value_objects/calendar_date.dart';
import '../../../domain/value_objects/orientation.dart';
import '../../../shared/formatters/date_format.dart';
import '../../../shared/guest/event_welcome_copy.dart';
import '../../../shared/guest/guest_welcome.dart';
import '../../../shared/templates/template_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/porcelain_button.dart';
import '../../../shared/widgets/porcelain_card.dart';
import '../../../shared/widgets/porcelain_sheet.dart';
import '../../../shared/widgets/porcelain_text_field.dart';
import '../../../shared/widgets/porcelain_toast.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/rendered_thumbnail.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/studio_material.dart';
import '../../../shared/widgets/tablet_frame.dart';
import '../../../shared/widgets/tactile_surface.dart';
import '../../../shared/widgets/tone.dart';
import '../editor/experience_card.dart';
import '../event_copy.dart';
import 'quick_event_designs.dart';

/// The three steps of a new event (UX-P1, CR-003).
enum QuickStep {
  occasion('Occasion'),
  look('Look'),
  ready('Ready');

  const QuickStep(this.label);

  final String label;
}

/// A new event in three steps (UX-P1, CR-003): its name and occasion; the
/// guest look and the photo design; then one tap creates it, makes it
/// active and opens its launch checks. Everything else starts from the
/// booth's defaults and stays in the event's settings for later. A
/// ready-made design joins the library when the event is created, and the
/// photos per guest follow the design, so a new event never starts with a
/// mismatch.
class QuickEventScreen extends ConsumerStatefulWidget {
  const QuickEventScreen({super.key});

  /// How many designs show before "Show all designs".
  static const shortList = 6;

  /// From this width the live preview and the step's actions sit in a
  /// pane beside the step.
  static const twoPaneWidth = 980.0;
  static const sidePaneWidth = 340.0;

  @override
  ConsumerState<QuickEventScreen> createState() => _QuickEventScreenState();
}

enum _Busy { creating, saving }

class _QuickEventScreenState extends ConsumerState<QuickEventScreen> {
  var _step = QuickStep.occasion;
  var _forward = true;
  BoothEvent? _draft;
  BoothEvent? _initial;
  QuickOccasion? _occasion;

  /// The design the operator picked; until then the best suited one is
  /// shown as chosen.
  String? _designKey;
  var _showTitleProblem = false;
  var _allDesigns = false;
  var _loadFailed = false;
  var _done = false;
  _Busy? _busy;
  final _title = TextEditingController();
  final _venue = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // A one-off read: an unlistened stream provider would stay paused.
      final booth = await ref.read(boothSettingsRepositoryProvider).load();
      final draft = ref.read(eventServiceProvider).newDraft(booth.profile);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _initial = draft;
      });
    } on Exception {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  bool get _touched {
    final draft = _draft;
    if (draft == null || _done) return false;
    return !draft.sameContentAs(_initial!) || _designKey != null;
  }

  String? get _titleProblem {
    final title = _draft?.title.trim() ?? '';
    if (title.isEmpty) return 'Give the event a name.';
    if (title.runes.length > EventLimits.titleMaxLength) {
      return 'Use at most ${EventLimits.titleMaxLength} characters.';
    }
    return null;
  }

  ExperiencePack get _pack =>
      ExperienceRegistry.bundled.pack(_draft!.experience.packId) ??
      ExperienceRegistry.bundled.fallback;

  void _update(BoothEvent event) => setState(() => _draft = event);

  /// [pack] chosen: a pack made for children asks for a guardian when
  /// guests text themselves (EP00 4.7).
  void _choosePack(ExperiencePack pack) {
    final draft = _draft!;
    final config = draft.experience;
    if (pack.packId == config.packId) return;
    _update(
      draft.copyWith(
        experience: config
            .switchPack(pack.packId, pack.packVersion)
            .copyWith(
              childrenMayBeGuests: ExperienceRegistry.childrenPackIds.contains(
                pack.packId,
              ),
            ),
      ),
    );
  }

  void _chooseOccasion(QuickOccasion occasion) {
    setState(() => _occasion = _occasion == occasion ? null : occasion);
    final pack = ExperienceRegistry.bundled.pack(occasion.packId);
    if (_occasion != null && pack != null) _choosePack(pack);
  }

  void _go(QuickStep step) {
    if (step == _step) return;
    if (step.index > QuickStep.occasion.index && _titleProblem != null) {
      setState(() {
        _showTitleProblem = true;
        _step = QuickStep.occasion;
      });
      return;
    }
    setState(() {
      _forward = step.index > _step.index;
      _step = step;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _pickDate() async {
    final draft = _draft!;
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.date?.toLocalDateTime() ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2999, 12, 31),
      helpText: 'Event date',
    );
    if (picked != null && mounted) {
      _update(_draft!.copyWith(date: CalendarDate.fromDateTime(picked)));
    }
  }

  /// The chosen design, or the best suited one until the operator picks.
  QuickDesign? _chosen(List<QuickDesign> designs) =>
      designs.firstWhereOrNull((d) => d.key == _designKey) ??
      designs.firstOrNull;

  /// Creates the event with [design]: the design joins the library first
  /// when it is a ready-made one. With [launch], the event is made active
  /// and its launch checks open; otherwise it stays a draft and opens in
  /// the editor. Nothing is claimed before it is stored.
  Future<void> _create(QuickDesign design, {required bool launch}) async {
    setState(() => _busy = launch ? _Busy.creating : _Busy.saving);
    try {
      final template = switch (design) {
        LibraryDesign(:final template) => template,
        StarterChoice(:final design) =>
          await ref
              .read(templateLibraryProvider)
              .create(design, name: design.name),
      };
      final draft = _draft!;
      final events = ref.read(eventServiceProvider);
      var saved = await events.save(
        draft.copyWith(
          title: draft.title.trim(),
          templates: const TemplateSelection().add(template.revisionId),
          capture: draft.capture.copyWith(shotCount: template.photoSlotCount),
        ),
      );
      var activated = false;
      if (launch) {
        try {
          saved = await events.activate(saved.id);
          activated = true;
        } on EventRuleException catch (error) {
          // Saved as a draft: the editor shows what to fix.
          _toast(
            error.issues.map(EventCopy.issue).join(' '),
            PorcelainTone.warning,
          );
        }
      }
      if (!mounted) return;
      setState(() => _done = true);
      if (activated) {
        _toast(
          '“${saved.title}” is ready. Run its launch checks to start.',
          PorcelainTone.success,
        );
        context.go(RoutePaths.preflight(saved.id));
      } else {
        if (!launch) {
          _toast(
            '“${saved.title}” is saved as a draft.',
            PorcelainTone.success,
          );
        }
        context.go(RoutePaths.event(saved.id));
      }
    } on TemplateStoreException catch (error) {
      _toast(TemplateMessages.storeError(error), PorcelainTone.danger);
    } on EventRuleException catch (error) {
      _toast(
        error.issues.map(EventCopy.issue).join(' '),
        PorcelainTone.warning,
      );
    } on Exception {
      _toast(
        "The event couldn't be created. Nothing was changed; try again.",
        PorcelainTone.danger,
      );
    } finally {
      if (mounted && !_done) setState(() => _busy = null);
    }
  }

  void _toast(String message, PorcelainTone tone) {
    if (mounted) PorcelainToast.show(context, message, tone: tone);
  }

  Future<bool> _confirmLeave() async {
    final leave = await showPorcelainSheet<bool>(
      context: context,
      title: 'Leave without creating the event?',
      body: const Text(
        'What you entered is not saved yet. Keep going to create it, or '
        'leave and start again later.',
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Keep going',
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
        PorcelainButton(
          label: 'Leave',
          icon: PorcelainIcons.close,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    );
    return leave ?? false;
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.events);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final library = ref.watch(selectableTemplatesProvider);
    final designs = draft == null
        ? const AsyncLoading<List<QuickDesign>>()
        : library.whenData(
            (templates) => quickDesigns(
              library: templates,
              starters: starterDesigns,
              pack: _pack,
              config: draft.experience,
            ),
          );
    final chosen = _chosen(designs.value ?? const []);

    return PopScope(
      canPop: !_touched || _busy != null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) {
          setState(() => _done = true);
          _leave();
        }
      },
      child: Scaffold(
        body: StudioMaterial(
          area: StudioMaterialArea.canvas,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                step: _step,
                reachable: (step) =>
                    step.index <= _step.index ||
                    (draft != null && _titleProblem == null),
                onStep: _go,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: _loadFailed
                    ? EmptyState(
                        icon: PorcelainIcons.error,
                        title: "A new event couldn't be started",
                        message: "The booth's settings could not be read.",
                        tone: PorcelainTone.danger,
                        actions: [
                          PorcelainButton(
                            label: 'Try again',
                            icon: PorcelainIcons.retry,
                            onPressed: () {
                              setState(() => _loadFailed = false);
                              unawaited(_load());
                            },
                          ),
                        ],
                      )
                    : draft == null
                    ? const Padding(
                        padding: EdgeInsets.all(PorcelainSpace.xxl),
                        child: SkeletonList(semanticLabel: 'Starting'),
                      )
                    : _body(draft, designs, chosen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The step's content, the live preview and the step's actions. On a
  /// wide window the preview and the actions sit in a pane beside the
  /// content and stay in view while it scrolls; otherwise they follow the
  /// content. Every scrolling area ends at the bottom of the screen:
  /// nothing scrolls under a bar.
  Widget _body(
    BoothEvent draft,
    AsyncValue<List<QuickDesign>> designs,
    QuickDesign? chosen,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= QuickEventScreen.twoPaneWidth;
        final margin = width >= 900
            ? PorcelainSpace.xxxl
            : width >= 600
            ? PorcelainSpace.xl
            : PorcelainSpace.md;
        final content = switch (_step) {
          QuickStep.occasion => _occasionStep(draft),
          QuickStep.look => _lookStep(draft, designs, chosen),
          QuickStep.ready => _readyStep(draft, chosen),
        };
        // No design is chosen on the first step: its preview is the
        // welcome alone.
        final preview = _LookPreview(
          event: draft,
          design: _step == QuickStep.occasion ? null : chosen,
          compact: wide,
        );
        final actions = _actions(chosen, stacked: wide);
        final page = _StepSwitcher(
          step: _step,
          forward: _forward,
          child: SingleChildScrollView(
            key: ValueKey(_step),
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(margin, margin, margin, margin * 2),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _step == QuickStep.look ? 1120 : 820,
                ),
                child: wide
                    ? content
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          content,
                          // The last step keeps its actions straight after
                          // the summary; the look was previewed before it.
                          if (_step == QuickStep.look) ...[
                            const SizedBox(height: PorcelainSpace.xxl),
                            const _SectionTitle(
                              title: 'Preview',
                              subtitle:
                                  'Their welcome, and the photos they take '
                                  'home.',
                            ),
                            preview,
                          ],
                          const SizedBox(height: PorcelainSpace.xxl),
                          actions,
                        ],
                      ),
              ),
            ),
          ),
        );
        if (!wide) return page;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: page),
            SizedBox(
              width: QuickEventScreen.sidePaneWidth,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  PorcelainSpace.xxl,
                  margin,
                  PorcelainSpace.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('PREVIEW', style: context.porcelain.text.eyebrow),
                    const SizedBox(height: PorcelainSpace.xs),
                    preview,
                    const SizedBox(height: PorcelainSpace.xl),
                    actions,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actions(QuickDesign? chosen, {required bool stacked}) {
    final busy = _busy;
    final List<Widget> buttons = switch (_step) {
      QuickStep.occasion => [
        PorcelainButton(
          label: 'Next: choose the look',
          icon: PorcelainIcons.chevron,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          onPressed: () => _go(QuickStep.look),
        ),
      ],
      QuickStep.look => [
        PorcelainButton(
          label: 'Back',
          icon: PorcelainIcons.back,
          size: PorcelainButtonSize.large,
          onPressed: () => _go(QuickStep.occasion),
        ),
        PorcelainButton(
          label: 'Next: review',
          icon: PorcelainIcons.chevron,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          onPressed: chosen == null ? null : () => _go(QuickStep.ready),
          disabledReason: 'Choose a photo design first.',
        ),
      ],
      QuickStep.ready => [
        PorcelainButton(
          label: 'Save as draft',
          icon: PorcelainIcons.draft,
          size: PorcelainButtonSize.large,
          busy: busy == _Busy.saving,
          busyLabel: 'Saving…',
          onPressed: chosen == null || busy != null
              ? null
              : () => _create(chosen, launch: false),
          disabledReason: busy == null
              ? 'Choose a photo design first.'
              : 'The event is being created.',
        ),
        PorcelainButton(
          label: 'Create and check the booth',
          icon: PorcelainIcons.ready,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          busy: busy == _Busy.creating,
          busyLabel: 'Creating…',
          onPressed: chosen == null || busy != null
              ? null
              : () => _create(chosen, launch: true),
          disabledReason: busy == null
              ? 'Choose a photo design first.'
              : 'The event is being created.',
        ),
      ],
    };
    return _StepActions(buttons: buttons, stacked: stacked);
  }

  // Step 1: the name, date and venue, and the occasion.

  Widget _occasionStep(BoothEvent draft) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final date = draft.date;
    final problem = _titleProblem;
    final showProblem =
        problem != null &&
        (_showTitleProblem ||
            draft.title.runes.length > EventLimits.titleMaxLength);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          eyebrow: 'New event',
          title: "Let's set up your event",
          subtitle:
              'Three quick steps. The camera, countdown, words and privacy '
              'start from your booth settings and can be fine-tuned later.',
        ),
        const SizedBox(height: PorcelainSpace.xl),
        PorcelainCard(
          padding: const EdgeInsets.all(PorcelainSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PorcelainTextField(
                label: 'Event name',
                controller: _title,
                hint: _occasion?.titleHint ?? 'e.g. Spring celebration',
                helper: showProblem
                    ? null
                    : 'For you and your team. Guests see the welcome words.',
                error: showProblem ? problem : null,
                maxLength: EventLimits.titleMaxLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (text) {
                  _update(_draft!.copyWith(title: text));
                  if (_showTitleProblem && _titleProblem == null) {
                    setState(() => _showTitleProblem = false);
                  }
                },
              ),
              const SizedBox(height: PorcelainSpace.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dateButton = MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Date', style: theme.text.labelLarge),
                        const SizedBox(height: PorcelainSpace.xs),
                        Wrap(
                          spacing: PorcelainSpace.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PorcelainButton(
                              label: date == null
                                  ? 'Choose a date'
                                  : formatCalendarDate(date),
                              icon: PorcelainIcons.events,
                              onPressed: _pickDate,
                            ),
                            if (date != null)
                              PorcelainIconButton(
                                icon: PorcelainIcons.close,
                                semanticLabel: 'Clear the date',
                                onPressed: () =>
                                    _update(_draft!.copyWith(date: null)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                  final venue = PorcelainTextField(
                    label: 'Venue',
                    controller: _venue,
                    hint: 'Optional',
                    maxLength: EventLimits.venueMaxLength,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (text) => _update(
                      _draft!.copyWith(
                        venue: text.trim().isEmpty ? null : text,
                      ),
                    ),
                  );
                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dateButton,
                        const SizedBox(height: PorcelainSpace.lg),
                        venue,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dateButton,
                      const SizedBox(width: PorcelainSpace.xl),
                      Expanded(child: venue),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxl),
        Semantics(
          header: true,
          child: Text("What's the occasion?", style: theme.text.headlineSmall),
        ),
        const SizedBox(height: PorcelainSpace.xxs),
        Text(
          'Optional. Picks a guest look that suits it; you can change it '
          'next.',
          style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.lg),
        Wrap(
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.sm,
          children: [
            for (final occasion in QuickOccasion.values)
              _OccasionChip(
                occasion: occasion,
                selected: occasion == _occasion,
                onPressed: () => _chooseOccasion(occasion),
              ),
          ],
        ),
      ],
    );
  }

  // Step 2: the guest experience and the photo design.

  Widget _lookStep(
    BoothEvent draft,
    AsyncValue<List<QuickDesign>> designs,
    QuickDesign? chosen,
  ) {
    final pack = _pack;
    final config = draft.experience;
    final experiences = Wrap(
      spacing: PorcelainSpace.md,
      runSpacing: PorcelainSpace.md,
      children: [
        for (final candidate in ExperienceRegistry.bundled.packs)
          ExperienceCard(
            experience: ExperienceRegistry.bundled.resolve(
              candidate.packId == config.packId
                  ? config
                  : config.switchPack(candidate.packId, candidate.packVersion),
            ),
            title: candidate.displayName,
            selected: candidate.packId == config.packId,
            onPressed: () => _choosePack(candidate),
          ),
      ],
    );
    final designList = switch (designs) {
      AsyncData(:final value) when value.isEmpty => const EmptyState(
        icon: PorcelainIcons.templates,
        title: 'No designs available',
        message: 'Import or design a template in Templates first.',
      ),
      AsyncData(:final value) => () {
        final yours = value.whereType<LibraryDesign>().toList();
        final readyMade = value.whereType<StarterChoice>().toList();
        final shortened =
            !_allDesigns && readyMade.length > QuickEventScreen.shortList + 1;
        Widget grid(Iterable<QuickDesign> designs) => ResponsiveGrid(
          minTileWidth: 150,
          maxColumns: 4,
          spacing: PorcelainSpace.md,
          children: [
            for (final design in designs)
              _DesignTile(
                design: design,
                selected: design.key == chosen?.key,
                suits: quickDesignScore(design, pack, config) >= 2
                    ? pack.displayName
                    : null,
                onPressed: () => setState(() => _designKey = design.key),
              ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (yours.isNotEmpty) ...[
              _GroupLabel('Your designs'),
              grid(yours),
              const SizedBox(height: PorcelainSpace.xl),
            ],
            if (readyMade.isNotEmpty) ...[
              _GroupLabel(
                yours.isEmpty ? 'Ready-made designs' : 'Or a ready-made one',
              ),
              grid(
                shortened
                    ? readyMade.take(QuickEventScreen.shortList)
                    : readyMade,
              ),
            ],
            if (shortened)
              Padding(
                padding: const EdgeInsets.only(top: PorcelainSpace.lg),
                child: Center(
                  child: PorcelainButton(
                    label: 'Show all ${readyMade.length} ready-made designs',
                    icon: PorcelainIcons.templates,
                    variant: PorcelainButtonVariant.quiet,
                    onPressed: () => setState(() => _allDesigns = true),
                  ),
                ),
              ),
          ],
        );
      }(),
      AsyncError() => const EmptyState(
        icon: PorcelainIcons.error,
        title: "The designs couldn't be loaded",
        message: 'Leave this page and open it again.',
        tone: PorcelainTone.danger,
      ),
      _ => const SkeletonList(semanticLabel: 'Loading designs'),
    };

    final choices = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          eyebrow: draft.title.trim(),
          title: 'Choose the look',
          subtitle:
              'How the guest screens look and sound, and the design of the '
              'photos guests take home.',
        ),
        const SizedBox(height: PorcelainSpace.xl),
        _SectionTitle(
          title: 'Guest experience',
          subtitle: 'Screens, buttons, countdown and sounds.',
        ),
        experiences,
        const SizedBox(height: PorcelainSpace.xxl),
        _SectionTitle(
          title: 'Photo design',
          subtitle:
              'Each design sets how many photos a guest takes. Designs that '
              'suit ${pack.displayName} come first.',
        ),
        designList,
      ],
    );

    return choices;
  }

  // Step 3: what the event will be, and one tap to create it.

  Widget _readyStep(BoothEvent draft, QuickDesign? chosen) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final pack = _pack;
    final capture = draft.capture;
    final photos = chosen?.photoSlots ?? capture.shotCount;
    final when = [
      if (draft.date != null) formatCalendarDate(draft.date!),
      if (draft.venue != null) draft.venue!,
    ].join(' · ');
    final facts = <(IconData, String, String)>[
      (PorcelainIcons.appearance, 'Guest experience', pack.displayName),
      (
        PorcelainIcons.templates,
        'Photo design',
        chosen == null
            ? 'Not chosen'
            : '${chosen.name} · ${EventCopy.photos(photos)} per guest'
                  '${chosen is StarterChoice ? ' · added to your templates' : ''}',
      ),
      (
        PorcelainIcons.countdown,
        'Countdown',
        '${capture.countdownSeconds} seconds before each photo',
      ),
      (
        PorcelainIcons.retry,
        'Retakes',
        switch (capture.retakePolicy) {
          RetakePolicy.none => 'Off',
          RetakePolicy.perShot =>
            capture.retakeLimit == 1
                ? 'One per photo'
                : 'Up to ${capture.retakeLimit} per photo',
          RetakePolicy.wholeSession =>
            capture.retakeLimit == 1
                ? 'The whole set, once'
                : 'The whole set, up to ${capture.retakeLimit} times',
        },
      ),
      (
        PorcelainIcons.camera,
        'Camera',
        '${EventCopy.lens(capture.lens)} · '
            '${EventCopy.orientation(capture.orientation).toLowerCase()} '
            'screens',
      ),
      (
        PorcelainIcons.textMessage,
        'Texting photos',
        'Off. Turn it on in the event once texting is set up.',
      ),
      (
        PorcelainIcons.storage,
        'Photos',
        'Kept on this device until you delete them',
      ),
    ];

    final summary = PorcelainCard(
      radius: PorcelainRadius.dialog,
      padding: const EdgeInsets.all(PorcelainSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('READY TO CREATE', style: theme.text.eyebrow),
          const SizedBox(height: PorcelainSpace.xs),
          Semantics(
            header: true,
            child: Text(
              draft.title.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.text.headlineLarge,
            ),
          ),
          if (when.isNotEmpty) ...[
            const SizedBox(height: PorcelainSpace.xxs),
            Text(
              when,
              style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
            ),
          ],
          const SizedBox(height: PorcelainSpace.lg),
          for (final (icon, label, value) in facts)
            _Fact(icon: icon, label: label, value: value),
          const SizedBox(height: PorcelainSpace.md),
          Text(
            'Creating it makes it active and opens its launch checks; '
            'Booth Mode starts from there. Every setting can be changed in '
            "the event's settings.",
            style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: PorcelainSpace.md),
          PorcelainButton(
            label: 'Preview the guest journey',
            icon: PorcelainIcons.preview,
            variant: PorcelainButtonVariant.quiet,
            onPressed: () => context.push(
              RoutePaths.experiencePreview,
              extra: switch (chosen) {
                LibraryDesign(:final template) => draft.copyWith(
                  templates: const TemplateSelection().add(template.revisionId),
                  capture: capture.copyWith(shotCount: photos),
                ),
                _ => draft.copyWith(
                  capture: capture.copyWith(shotCount: photos),
                ),
              },
            ),
          ),
        ],
      ),
    );

    return summary;
  }
}

/// The step trail and the way back to Events.
class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.reachable,
    required this.onStep,
    required this.onBack,
  });

  final QuickStep step;
  final bool Function(QuickStep step) reachable;
  final ValueChanged<QuickStep> onStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.rail,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PorcelainSpace.md,
            vertical: PorcelainSpace.sm,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final trail = _StepTrail(
                current: step,
                reachable: reachable,
                onStep: onStep,
                showLabels: !compact,
              );
              return Row(
                children: [
                  PorcelainButton(
                    label: 'Events',
                    icon: PorcelainIcons.back,
                    variant: PorcelainButtonVariant.quiet,
                    size: PorcelainButtonSize.compact,
                    onPressed: onBack,
                  ),
                  const SizedBox(width: PorcelainSpace.sm),
                  if (!compact) ...[
                    Semantics(
                      header: true,
                      child: Text('New event', style: theme.text.titleLarge),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  trail,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Three numbered steps joined by a line that fills as they are done.
/// Steps already reached can be revisited.
class _StepTrail extends StatelessWidget {
  const _StepTrail({
    required this.current,
    required this.reachable,
    required this.onStep,
    required this.showLabels,
  });

  final QuickStep current;
  final bool Function(QuickStep step) reachable;
  final ValueChanged<QuickStep> onStep;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final children = <Widget>[];
    for (final step in QuickStep.values) {
      if (step.index > 0) {
        final done = step.index <= current.index;
        children.add(
          AnimatedContainer(
            duration: motion.emphasized,
            curve: PorcelainMotion.ease,
            width: showLabels ? 28 : 20,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: PorcelainSpace.xs),
            decoration: BoxDecoration(
              color: done ? colors.accentIcon : colors.hairline,
              borderRadius: const BorderRadius.all(Radius.circular(1)),
            ),
          ),
        );
      }
      final state = step == current
          ? _NodeState.current
          : step.index < current.index
          ? _NodeState.done
          : _NodeState.upcoming;
      final label =
          'Step ${step.index + 1} of ${QuickStep.values.length}: '
          '${step.label}';
      Widget node(bool focused) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: PorcelainSize.minTouchTarget,
          minHeight: PorcelainSize.minTouchTarget,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepNode(number: step.index + 1, state: state, focused: focused),
            if (showLabels) ...[
              const SizedBox(width: PorcelainSpace.xs),
              Text(
                step.label,
                style: theme.text.labelLarge.copyWith(
                  color: state == _NodeState.upcoming
                      ? colors.inkMuted
                      : colors.ink,
                  fontWeight: state == _NodeState.current
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
      // The current step is where the operator is, not a control.
      children.add(
        step == current
            ? Semantics(
                label: label,
                selected: true,
                child: ExcludeSemantics(child: node(false)),
              )
            : Pressable(
                onPressed: reachable(step) ? () => onStep(step) : null,
                disabledReason: 'Give the event a name first.',
                semanticLabel: label,
                builder: (context, press) => node(press.focused),
              ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

enum _NodeState { done, current, upcoming }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.state,
    required this.focused,
  });

  final int number;
  final _NodeState state;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final filled = state != _NodeState.upcoming;
    return AnimatedContainer(
      duration: motion.standard,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.primaryTop, colors.primaryBottom],
              )
            : null,
        color: filled ? null : colors.surface,
        border: Border.all(
          color: focused
              ? colors.focusRing
              : filled
              ? colors.primaryEdge
              : colors.outline,
          width: focused ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: state == _NodeState.done
          ? Icon(PorcelainIcons.check, size: 18, color: colors.onPrimary)
          : Text(
              '$number',
              style: theme.text.labelLarge.copyWith(
                color: filled ? colors.onPrimary : colors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Changes step with a short fade and a slide in the direction of travel
/// (a plain cut with reduced motion).
class _StepSwitcher extends StatelessWidget {
  const _StepSwitcher({
    required this.step,
    required this.forward,
    required this.child,
  });

  final QuickStep step;
  final bool forward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = PorcelainMotion.of(context);
    return AnimatedSwitcher(
      duration: motion.page,
      switchInCurve: PorcelainMotion.enter,
      switchOutCurve: PorcelainMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(step);
        final offset = Tween<Offset>(
          begin: Offset((incoming == forward ? 1 : -1) * 0.04, 0),
          end: Offset.zero,
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offset.animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The step's actions, the main one first when [stacked] (and on narrow
/// windows, where the buttons share the width).
class _StepActions extends StatelessWidget {
  const _StepActions({required this.buttons, required this.stacked});

  final List<Widget> buttons;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (stacked || constraints.maxWidth < 560) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, button) in buttons.reversed.indexed) ...[
                if (i > 0) const SizedBox(height: PorcelainSpace.xs),
                button,
              ],
            ],
          );
        }
        // Side by side (Back apart from the rest), wrapping onto a second
        // line only when they do not fit, e.g. with very large text.
        return Wrap(
          alignment: buttons.length > 1
              ? WrapAlignment.spaceBetween
              : WrapAlignment.end,
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.xs,
          children: buttons,
        );
      },
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow.isNotEmpty) ...[
          Text(
            eyebrow.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text.eyebrow,
          ),
          const SizedBox(height: PorcelainSpace.xs),
        ],
        Semantics(
          header: true,
          child: Text(title, style: theme.text.displaySmall),
        ),
        const SizedBox(height: PorcelainSpace.xs),
        Text(
          subtitle,
          style: theme.text.bodyLarge.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.text.headlineSmall),
          ),
          const SizedBox(height: PorcelainSpace.xxs),
          Text(
            subtitle,
            style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
      child: Text(text.toUpperCase(), style: theme.text.eyebrow),
    );
  }
}

/// One occasion: a porcelain pill with its icon; gilded when chosen.
class _OccasionChip extends StatelessWidget {
  const _OccasionChip({
    required this.occasion,
    required this.selected,
    required this.onPressed,
  });

  final QuickOccasion occasion;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: occasion.label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      builder: (context, state) => TactileSurface(
        look: state.pressed
            ? TactileLook(
                fillTop: colors.inset,
                fillBottom: colors.inset,
                border: colors.outline,
                inset: 0.6,
                travel: 1,
              )
            : selected
            ? TactileLook(
                fillTop: colors.selected,
                fillBottom: colors.selected,
                border: colors.primaryEdge,
                borderWidth: 2,
                elevation: 0.6,
              )
            : TactileLook(
                fillTop: colors.raised,
                fillBottom: colors.surface,
                border: state.hovered ? colors.outline : colors.hairline,
                elevation: state.hovered ? 0.8 : 0.4,
                highlight: 0.8,
              ),
        shape: TactileShape.stadium,
        focused: state.focused,
        duration: state.pressed ? motion.press : motion.release,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: PorcelainSize.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PorcelainSpace.md,
              vertical: PorcelainSpace.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? PorcelainIcons.check : occasion.icon,
                  size: PorcelainSize.iconSmall,
                  color: colors.accentIcon,
                  fill: selected ? 1 : 0,
                ),
                const SizedBox(width: PorcelainSpace.xs),
                Text(
                  occasion.label,
                  style: theme.text.labelLarge.copyWith(
                    color: colors.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A photo design drawn as it prints, with its name and photo count.
class _DesignTile extends StatelessWidget {
  const _DesignTile({
    required this.design,
    required this.selected,
    required this.suits,
    required this.onPressed,
  });

  final QuickDesign design;
  final bool selected;

  /// The guest experience it was made for, when it suits the chosen one.
  final String? suits;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final design = this.design;
    return PorcelainCard(
      onPressed: onPressed,
      selected: selected,
      semanticLabel:
          '${design.name}, ${EventCopy.photos(design.photoSlots)}'
          '${suits == null ? '' : ', suits $suits'}',
      padding: const EdgeInsets.all(PorcelainSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Center(
              child: RenderedThumbnail(
                thumbnail: switch (design) {
                  LibraryDesign(:final template) => templateThumbnailProvider(
                    template.revisionId,
                  ),
                  StarterChoice(:final design) => starterThumbnailProvider(
                    design.id,
                  ),
                },
                aspectRatio: design.aspectRatio,
                semanticLabel: design.name,
              ),
            ),
          ),
          const SizedBox(height: PorcelainSpace.sm),
          Text(
            design.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text.titleSmall,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(PorcelainIcons.camera, size: 16, color: colors.accentIcon),
              const SizedBox(width: PorcelainSpace.xxs),
              Expanded(
                child: Text(
                  EventCopy.photos(design.photoSlots),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
                ),
              ),
            ],
          ),
          if (suits != null) ...[
            const SizedBox(height: PorcelainSpace.xs),
            const StatusBadge(
              label: 'Suits this look',
              icon: PorcelainIcons.suggested,
              tone: PorcelainTone.info,
            ),
          ],
        ],
      ),
    );
  }
}

/// What guests will see: the welcome in the chosen look, and the chosen
/// design as it prints.
class _LookPreview extends StatelessWidget {
  const _LookPreview({
    required this.event,
    required this.design,
    required this.compact,
  });

  final BoothEvent event;
  final QuickDesign? design;

  /// Sized to fit the side pane above the step's actions.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final experience = ExperienceRegistry.bundled.resolve(event.experience);
    final landscape =
        event.capture.orientation == GuestOrientationPreference.landscape;
    final frame = landscape ? const Size(1180, 820) : const Size(820, 1180);
    final design = this.design;
    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final welcome = GuestExperienceScope(
            experience: experience,
            child: AspectRatio(
              aspectRatio: (frame.width + 18) / (frame.height + 18),
              child: TabletFrame(
                logicalSize: frame,
                semanticLabel:
                    'Preview of the guest welcome in '
                    '${experience.displayName}',
                child: GuestWelcome(
                  copy: welcomeCopyFor(event),
                  onStart: () {},
                ),
              ),
            ),
          );
          final print = design == null
              ? const SizedBox.shrink()
              : SizedBox(
                  height: compact ? 150 : 180,
                  child: Center(
                    child: RenderedThumbnail(
                      thumbnail: switch (design) {
                        LibraryDesign(:final template) =>
                          templateThumbnailProvider(template.revisionId),
                        StarterChoice(:final design) =>
                          starterThumbnailProvider(design.id),
                      },
                      aspectRatio: design.aspectRatio,
                      semanticLabel: 'The photo design ${design.name}',
                    ),
                  ),
                );
          Widget caption(String text) => Text(
            text,
            textAlign: TextAlign.center,
            style: theme.text.labelMedium.copyWith(color: colors.inkMuted),
          );
          // Side by side when the card is wide but not tall.
          if (!compact && constraints.maxWidth >= 520) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 220, child: Center(child: welcome)),
                      const SizedBox(height: PorcelainSpace.sm),
                      caption('Their welcome'),
                    ],
                  ),
                ),
                if (design != null) ...[
                  const SizedBox(width: PorcelainSpace.lg),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 220, child: print),
                        const SizedBox(height: PorcelainSpace.sm),
                        caption(
                          '${EventCopy.photos(design.photoSlots)} per guest',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }
          return Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: compact ? 200 : 300),
                child: welcome,
              ),
              const SizedBox(height: PorcelainSpace.sm),
              caption('Their welcome'),
              if (design != null) ...[
                const SizedBox(height: PorcelainSpace.lg),
                print,
                const SizedBox(height: PorcelainSpace.sm),
                caption(
                  '${design.name} · ${EventCopy.photos(design.photoSlots)} '
                  'per guest',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.selected,
                border: Border.all(color: colors.hairline),
              ),
              child: Icon(icon, size: 18, color: colors.accentIcon),
            ),
            const SizedBox(width: PorcelainSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.text.labelMedium.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: theme.text.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
