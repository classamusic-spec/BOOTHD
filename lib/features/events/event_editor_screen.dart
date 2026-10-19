import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/appearance.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/event_rules.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/services/event_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import 'editor/capture_tab.dart';
import 'editor/delivery_tab.dart';
import 'editor/editor_parts.dart';
import 'editor/general_tab.dart';
import 'editor/guest_tab.dart';
import 'editor/output_tab.dart';
import 'editor/privacy_tab.dart';
import 'editor/templates_tab.dart';
import 'event_actions.dart';
import 'event_copy.dart';

/// The editor's sections (S04).
enum EventEditorTab {
  general('Event', PorcelainIcons.events),
  guest('Experience', PorcelainIcons.appearance),
  templates('Templates', PorcelainIcons.templates),
  capture('Camera', PorcelainIcons.camera),
  output('Output', PorcelainIcons.outputFormat),
  privacy('Privacy', PorcelainIcons.privacy),
  delivery('Texting', PorcelainIcons.textMessage);

  const EventEditorTab(this.label, this.icon);

  final String label;
  final IconData icon;

  static EventEditorTab fromName(String? name) =>
      values.firstWhereOrNull((tab) => tab.name == name) ?? general;

  /// Where the operator fixes [issue].
  static EventEditorTab forIssue(EventIssue issue) => switch (issue) {
    TitleRequired() => general,
    TextTooLong(field: EventTextField.welcomeTitle) ||
    TextTooLong(field: EventTextField.welcomeMessage) => guest,
    TextTooLong(field: EventTextField.consentText) => privacy,
    TextTooLong() => general,
    SettingOutOfRange(setting: EventSetting.finishTimeoutSeconds) => guest,
    SettingOutOfRange(setting: EventSetting.jpegQuality) => output,
    SettingOutOfRange(setting: EventSetting.retentionDays) => privacy,
    SettingOutOfRange() => capture,
    EventNotActive() => general,
    _ => templates,
  };
}

/// The event editor (S04): seven sections, saved together and atomically.
/// Unsaved changes are guarded; archived events are read-only until
/// reopened. Validation is live: problems that stop saving, and those that
/// only stop activation, are listed above the section with a way to them.
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({
    super.key,
    required String this.eventId,
    this.tab = EventEditorTab.general,
  });

  /// A new event, saved for the first time with Save.
  const EventEditorScreen.create({super.key})
    : eventId = null,
      tab = EventEditorTab.general;

  final String? eventId;
  final EventEditorTab tab;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  late EventEditorTab _tab = widget.tab;
  BoothEvent? _draft;

  /// What is stored; null until a new event is first saved.
  BoothEvent? _saved;

  /// The draft as first opened, to tell whether a new event was touched.
  BoothEvent? _initial;
  var _library = <String, TemplateRevisionSummary>{};
  var _saving = false;
  var _loadFailed = false;
  var _notFound = false;
  ProviderSubscription<AsyncValue<List<TemplateRevisionSummary>>>? _selectable;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _selectable = ref.listenManual(selectableTemplatesProvider, (_, next) {
      final templates = next.value;
      if (templates == null) return;
      setState(() {
        _library = {
          ..._library,
          for (final template in templates) template.revisionId: template,
        };
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _selectable?.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final id = widget.eventId;
      final BoothEvent? event;
      if (id == null) {
        // A one-off read: an unlistened stream provider would stay paused.
        final booth = await ref.read(boothSettingsRepositoryProvider).load();
        event = ref.read(eventServiceProvider).newDraft(booth.profile);
      } else {
        event = await ref.read(eventRepositoryProvider).findById(id);
      }
      if (event == null) {
        if (mounted) setState(() => _notFound = true);
        return;
      }
      final referenced = await ref
          .read(templateCatalogProvider)
          .findRevisions(event.templates.revisionIds);
      if (!mounted) return;
      setState(() {
        _draft = event;
        _initial = event;
        _saved = id == null ? null : event;
        _library = {..._library, ...referenced};
      });
    } on Exception {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  bool get _dirty {
    final draft = _draft;
    if (draft == null) return false;
    final base = _saved ?? _initial!;
    return !draft.sameContentAs(base);
  }

  List<EventIssue> get _structural => EventRules.structuralIssues(
    _draft!.copyWith(title: _draft!.title.trim()),
  );

  List<EventIssue> get _issues => [
    ..._structural,
    ...EventRules.templateIssues(_draft!, _library),
  ];

  String? get _readOnlyReason => _saved?.status == EventStatus.archived
      ? EventCopy.archivedReadOnly
      : null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await ref.read(eventServiceProvider).save(_draft!);
      if (!mounted) return;
      final created = _saved == null;
      setState(() {
        _saved = saved;
        _draft = saved;
        _saving = false;
      });
      PorcelainToast.show(context, 'Saved.', tone: PorcelainTone.success);
      if (created) {
        unawaited(
          GoRouter.of(context)
              .replace<void>(RoutePaths.event(saved.id, tab: _tab.name)),
        );
      }
    } on EventRuleException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      PorcelainToast.show(
        context,
        error.issues.map(_issueText).join(' '),
        tone: PorcelainTone.warning,
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      PorcelainToast.show(
        context,
        "The event couldn't be saved. Your changes are still here; try "
        'again.',
        tone: PorcelainTone.danger,
      );
    }
  }

  String _issueText(EventIssue issue) => EventCopy.issue(
    issue,
    templateName: (id) => _library[id]?.templateName ?? 'A template',
  );

  /// After a lifecycle change, the stored event is the new baseline.
  void _adopt(BoothEvent? result) {
    if (result == null || !mounted) return;
    setState(() {
      _saved = result;
      _draft = result;
    });
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showPorcelainSheet<bool>(
      context: context,
      title: 'Discard your changes?',
      body: const Text(
        'They have not been saved. Keep editing to save them, or discard '
        'them and leave.',
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Keep editing',
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
        PorcelainButton(
          label: 'Discard',
          icon: PorcelainIcons.close,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    );
    return discard ?? false;
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
    final theme = context.porcelain;
    final draft = _draft;
    final dirty = _dirty;
    return PopScope(
      canPop: !dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          setState(() {
            _draft = _saved ?? _initial;
          });
          _leave();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            _Header(
              title: draft == null
                  ? 'Event'
                  : draft.title.trim().isEmpty
                  ? 'New event'
                  : draft.title.trim(),
              status: _saved?.status,
              dirty: dirty,
              saving: _saving,
              canSave: draft != null && !hasInvalid(_structural),
              readOnlyReason: draft == null ? null : _readOnlyReason,
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _save,
            ),
            Expanded(
              child: _notFound
                  ? EmptyState(
                      icon: PorcelainIcons.events,
                      title: 'This event no longer exists',
                      message: 'It may have been removed. Return to Events.',
                      actions: [
                        PorcelainButton(
                          label: 'Back to Events',
                          icon: PorcelainIcons.back,
                          onPressed: () => context.go(RoutePaths.events),
                        ),
                      ],
                    )
                  : _loadFailed
                  ? EmptyState(
                      icon: PorcelainIcons.error,
                      title: "The event couldn't be opened",
                      message: 'Its storage could not be read. Try again.',
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
                      child: SkeletonList(semanticLabel: 'Loading the event'),
                    )
                  : _body(theme, draft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(PorcelainTheme theme, BoothEvent draft) {
    final tabContext = EditorTabContext(
      event: draft,
      library: _library,
      readOnlyReason: _readOnlyReason,
      onChanged: (event) => setState(() => _draft = event),
    );
    final content = KeyedSubtree(
      key: ValueKey(_tab),
      child: switch (_tab) {
        EventEditorTab.general => GeneralTab(
          tab: tabContext,
          status: _StatusCard(
            saved: _saved,
            dirty: _dirty,
            issues: _issues,
            issueText: _issueText,
            onChanged: _adopt,
          ),
        ),
        EventEditorTab.templates => TemplatesTab(tab: tabContext),
        EventEditorTab.capture => CaptureTab(tab: tabContext),
        EventEditorTab.guest => GuestTab(
          tab: tabContext,
          boothTheme: ref.watch(appearanceProvider).profile,
        ),
        EventEditorTab.output => OutputTab(tab: tabContext),
        EventEditorTab.privacy => PrivacyTab(tab: tabContext),
        EventEditorTab.delivery => DeliveryTab(tab: tabContext),
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final margin = wide ? PorcelainSpace.xxxl : PorcelainSpace.xl;
        final scroll = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(margin, margin, margin, margin * 2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IssueSummary(
                    issues: _issues,
                    status: _saved?.status ?? EventStatus.draft,
                    issueText: _issueText,
                    current: _tab,
                    onOpen: (tab) => setState(() => _tab = tab),
                  ),
                  content,
                ],
              ),
            ),
          ),
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 264,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(PorcelainSpace.lg),
                  child: Column(
                    children: [
                      for (final tab in EventEditorTab.values)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: PorcelainSpace.xxs,
                          ),
                          child: PorcelainListRow(
                            icon: tab.icon,
                            title: tab.label,
                            selected: tab == _tab,
                            showChevron: false,
                            onPressed: () => setState(() => _tab = tab),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(width: 1, color: theme.colors.divider),
              Expanded(child: scroll),
            ],
          );
        }
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                PorcelainSpace.xl,
                PorcelainSpace.md,
                PorcelainSpace.xl,
                0,
              ),
              child: PorcelainSegmentedControl<EventEditorTab>(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
                segments: [
                  for (final tab in EventEditorTab.values)
                    PorcelainSegment(value: tab, label: tab.label),
                ],
              ),
            ),
            Expanded(child: scroll),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.status,
    required this.dirty,
    required this.saving,
    required this.canSave,
    required this.readOnlyReason,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final EventStatus? status;
  final bool dirty;
  final bool saving;
  final bool canSave;
  final String? readOnlyReason;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final status = this.status;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.rail,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PorcelainSpace.lg,
            vertical: PorcelainSpace.sm,
          ),
          child: Row(
            children: [
              PorcelainButton(
                label: 'Events',
                icon: PorcelainIcons.back,
                variant: PorcelainButtonVariant.quiet,
                size: PorcelainButtonSize.compact,
                onPressed: onBack,
              ),
              const SizedBox(width: PorcelainSpace.md),
              Expanded(
                child: Wrap(
                  spacing: PorcelainSpace.sm,
                  runSpacing: PorcelainSpace.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text.titleLarge,
                      ),
                    ),
                    StatusBadge(
                      label: status == null
                          ? 'Not saved yet'
                          : EventCopy.status(status),
                      tone: status == null
                          ? PorcelainTone.neutral
                          : EventCopy.statusTone(status),
                      icon: status == null
                          ? PorcelainIcons.draft
                          : EventCopy.statusIcon(status),
                    ),
                    if (dirty && readOnlyReason == null)
                      const StatusBadge(
                        label: 'Unsaved changes',
                        tone: PorcelainTone.warning,
                        icon: PorcelainIcons.edit,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: PorcelainSpace.md),
              PorcelainButton(
                label: 'Save',
                icon: PorcelainIcons.check,
                variant: PorcelainButtonVariant.primary,
                busy: saving,
                busyLabel: 'Saving…',
                onPressed: readOnlyReason == null && dirty && canSave
                    ? onSave
                    : null,
                disabledReason:
                    readOnlyReason ??
                    (!dirty
                        ? 'Nothing has changed since the last save.'
                        : 'Fix the problems listed first.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Problems with the event, grouped by what they stop, each with a link to
/// the section that fixes it.
class _IssueSummary extends StatelessWidget {
  const _IssueSummary({
    required this.issues,
    required this.status,
    required this.issueText,
    required this.current,
    required this.onOpen,
  });

  final List<EventIssue> issues;
  final EventStatus status;
  final String Function(EventIssue) issueText;
  final EventEditorTab current;
  final ValueChanged<EventEditorTab> onOpen;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty || status == EventStatus.archived) {
      return const SizedBox.shrink();
    }
    final theme = context.porcelain;
    final colors = theme.colors;
    final invalid = hasInvalid(issues);
    final blocking = issues.any((i) => i.level == IssueLevel.blocking);
    final tone = invalid
        ? PorcelainTone.danger
        : blocking
        ? PorcelainTone.warning
        : PorcelainTone.info;
    final title = invalid
        ? 'Fix before saving'
        : blocking
        ? (status == EventStatus.active
              ? 'Fix before this event can launch'
              : 'Needed before this event can be activated')
        : 'Worth a look';
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.xl),
      child: PorcelainCard(
        padding: const EdgeInsets.all(PorcelainSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  invalid ? PorcelainIcons.error : PorcelainIcons.warning,
                  color: tone.foreground(colors),
                  fill: 1,
                ),
                const SizedBox(width: PorcelainSpace.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.text.titleMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PorcelainSpace.sm),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: PorcelainSpace.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        issueText(issue),
                        style: theme.text.bodyMedium.copyWith(
                          color: issue.level == IssueLevel.invalid
                              ? colors.danger
                              : colors.ink,
                        ),
                      ),
                    ),
                    if (EventEditorTab.forIssue(issue) != current) ...[
                      const SizedBox(width: PorcelainSpace.sm),
                      PorcelainButton(
                        label: EventEditorTab.forIssue(issue).label,
                        variant: PorcelainButtonVariant.quiet,
                        size: PorcelainButtonSize.compact,
                        onPressed: () => onOpen(EventEditorTab.forIssue(issue)),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The event's lifecycle and what can be done next (P-05).
class _StatusCard extends ConsumerWidget {
  const _StatusCard({
    required this.saved,
    required this.dirty,
    required this.issues,
    required this.issueText,
    required this.onChanged,
  });

  final BoothEvent? saved;
  final bool dirty;
  final List<EventIssue> issues;
  final String Function(EventIssue) issueText;
  final ValueChanged<BoothEvent?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = this.saved;
    if (saved == null) {
      return const EditorCard(
        title: 'Status',
        subtitle:
            'New events are saved as drafts. Save it, then activate it once '
            'its templates and settings are complete.',
        children: [],
      );
    }
    final blocking = EventRules.blocksActivation(issues);
    final (subtitle, actions) = switch (saved.status) {
      EventStatus.draft => (
        'A draft can be edited freely but cannot run the booth.',
        <Widget>[
          PorcelainButton(
            label: 'Activate event',
            icon: PorcelainIcons.active,
            variant: PorcelainButtonVariant.primary,
            onPressed: !dirty && !blocking
                ? () async => onChanged(
                    await EventActions.activate(context, ref, saved),
                  )
                : null,
            disabledReason: dirty
                ? 'Save your changes first.'
                : 'First fix what is listed at the top.',
          ),
        ],
      ),
      EventStatus.active => (
        'Active: it can run the booth once the launch checks pass.',
        <Widget>[
          PorcelainButton(
            label: 'Launch checks',
            icon: PorcelainIcons.preflight,
            variant: PorcelainButtonVariant.primary,
            onPressed: dirty
                ? null
                : () => context.push(RoutePaths.preflight(saved.id)),
            disabledReason: 'Save your changes first.',
          ),
          PorcelainButton(
            label: 'Return to drafts',
            icon: PorcelainIcons.draft,
            onPressed: () async => onChanged(
              await EventActions.returnToDraft(context, ref, saved),
            ),
          ),
        ],
      ),
      EventStatus.archived => (
        'Archived: kept with all its photos, read-only until reopened.',
        <Widget>[
          PorcelainButton(
            label: 'Reopen as draft',
            icon: PorcelainIcons.restore,
            variant: PorcelainButtonVariant.primary,
            onPressed: () async =>
                onChanged(await EventActions.reopen(context, ref, saved)),
          ),
        ],
      ),
    };
    return EditorCard(
      title: 'Status',
      subtitle: subtitle,
      trailing: StatusBadge(
        label: EventCopy.status(saved.status),
        tone: EventCopy.statusTone(saved.status),
        icon: EventCopy.statusIcon(saved.status),
      ),
      children: [
        Wrap(
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.sm,
          children: [
            ...actions,
            PorcelainButton(
              label: 'Duplicate',
              icon: PorcelainIcons.duplicate,
              onPressed: dirty
                  ? null
                  : () async {
                      final copy = await EventActions.duplicate(
                        context,
                        ref,
                        saved,
                      );
                      if (copy != null && context.mounted) {
                        context.go(RoutePaths.event(copy.id));
                      }
                    },
              disabledReason: 'Save your changes first.',
            ),
            if (saved.status != EventStatus.archived)
              PorcelainButton(
                label: 'Archive',
                icon: PorcelainIcons.archive,
                variant: PorcelainButtonVariant.danger,
                onPressed: dirty
                    ? null
                    : () async => onChanged(
                        await EventActions.archive(context, ref, saved),
                      ),
                disabledReason: 'Save or discard your changes first.',
              ),
          ],
        ),
      ],
    );
  }
}
