import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../domain/delivery/consent.dart';
import '../../domain/delivery/delivery_intent.dart';
import '../../domain/delivery/phone_number.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/tactile_surface.dart';
import 'delivery_copy.dart';
import 'guest_finished.dart';
import 'guest_parts.dart';

/// The sender's details shown with the consent (from the service).
@immutable
final class DeliveryTerms {
  const DeliveryTerms({
    required this.brand,
    required this.privacyUrl,
    required this.termsUrl,
    required this.supportContact,
  });

  final String brand;
  final String privacyUrl;
  final String termsUrl;
  final String supportContact;
}

enum _Step { choice, entry, result }

/// S30 to S32 for one finished session (UX-PD1 to UX-PD3, UX-PD7).
///
/// The photo is already saved. The guest may text it to themselves or
/// finish; either way they are never kept waiting for a text. The number
/// lives only in this screen's memory until the request is stored (then in
/// secure storage), is shown in full only to the guest while typing and
/// confirming, and is gone when the booth resets. The consent box starts
/// unchecked and is about this one text only.
class GuestDeliveryFlow extends StatefulWidget {
  const GuestDeliveryFlow({
    super.key,
    required this.photo,
    required this.aspect,
    required this.offline,
    required this.terms,
    required this.linkDays,
    required this.onSubmit,
    required this.watch,
    required this.onActivity,
    required this.onFinish,
  });

  final Uint8List photo;
  final double aspect;

  /// The text would wait for a connection (offered while offline).
  final bool offline;
  final DeliveryTerms terms;
  final int linkDays;

  /// Stores the request; returns its id. Throws when it could not be kept.
  final Future<String> Function(PhoneNumber phone, ConsentText consent)
  onSubmit;

  /// The stored request, as it changes.
  final Stream<DeliveryIntent?> Function(String intentId) watch;

  /// The guest touched something: the booth waits again before resetting.
  final VoidCallback onActivity;

  /// Done, No thanks: back to the welcome for the next guest.
  final VoidCallback onFinish;

  @override
  State<GuestDeliveryFlow> createState() => _GuestDeliveryFlowState();
}

class _GuestDeliveryFlowState extends State<GuestDeliveryFlow> {
  var _step = _Step.choice;
  var _digits = '';
  var _consent = false;
  var _confirming = false;
  var _sending = false;
  String? _info;
  String? _intentId;
  PhoneNumber? _sentTo;
  var _failed = false;

  late final _consentText = ConsentText(
    brand: widget.terms.brand,
    linkDays: widget.linkDays,
  );

  PhoneParse? get _parsed =>
      _digits.length == 10 ? parseUsPhone(_digits) : null;

  void _touch(VoidCallback change) {
    widget.onActivity();
    setState(change);
  }

  void _digit(String digit) {
    if (_digits.length >= 10 || _confirming) return;
    _touch(() => _digits += digit);
  }

  void _delete() {
    if (_digits.isEmpty || _confirming) return;
    _touch(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _send() async {
    final number = _parsed?.number;
    if (number == null || !_consent || _sending) return;
    _touch(() => _sending = true);
    try {
      final id = await widget.onSubmit(number, _consentText);
      if (!mounted) return;
      setState(() {
        _intentId = id;
        _sentTo = number;
        _step = _Step.result;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _sentTo = number;
        _step = _Step.result;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _confirming = false;
          // The guest's entry is no longer needed on screen.
          _digits = '';
          _consent = false;
        });
      }
    }
  }

  bool _key(KeyEvent event) {
    if (event is! KeyDownEvent || _step != _Step.entry) return false;
    final key = event.logicalKey;
    final character = event.character;
    if (character != null && RegExp(r'^[0-9]$').hasMatch(character)) {
      _digit(character);
      return true;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _delete();
      return true;
    }
    if (key == LogicalKeyboardKey.enter && _parsed?.ok == true && _consent) {
      _touch(() => _confirming = true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.choice => GuestFinished(
        photo: widget.photo,
        aspect: widget.aspect,
        offline: widget.offline,
        onTextPhotos: () => _touch(() => _step = _Step.entry),
        onNextGuest: widget.onFinish,
      ),
      _Step.entry => Focus(
        autofocus: true,
        onKeyEvent: (_, event) =>
            _key(event) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: Stack(
          children: [
            Positioned.fill(
              // Behind a card, the entry is not there for screen readers
              // (the card's scrim already takes every touch).
              child: ExcludeSemantics(
                excluding: _confirming || _info != null,
                child: _PhoneEntry(
                  photo: widget.photo,
                  aspect: widget.aspect,
                  digits: _digits,
                  parsed: _parsed,
                  consent: _consent,
                  consentText: _consentText.text,
                  onDigit: _digit,
                  onDelete: _delete,
                  onClear: () => _touch(() => _digits = ''),
                  onToggleConsent: () => _touch(() => _consent = !_consent),
                  onSend: () => _touch(() => _confirming = true),
                  onNoThanks: widget.onFinish,
                  onPrivacy: () =>
                      _touch(() => _info = DeliveryCopy.privacyTitle),
                  onTerms: () => _touch(() => _info = DeliveryCopy.termsTitle),
                ),
              ),
            ),
            if (_confirming)
              Positioned.fill(
                child: _GuestOverlay(
                  title: DeliveryCopy.confirmTitle,
                  body: _parsed?.number?.national ?? '',
                  bodyIsNumber: true,
                  actions: [
                    PorcelainButton(
                      label: DeliveryCopy.editNumber,
                      icon: PorcelainIcons.edit,
                      size: PorcelainButtonSize.large,
                      onPressed: _sending
                          ? null
                          : () => _touch(() => _confirming = false),
                    ),
                    PorcelainButton(
                      label: DeliveryCopy.send,
                      icon: PorcelainIcons.send,
                      variant: PorcelainButtonVariant.primary,
                      size: PorcelainButtonSize.large,
                      busy: _sending,
                      onPressed: _sending ? null : () => unawaited(_send()),
                    ),
                  ],
                ),
              ),
            if (_info case final info?)
              Positioned.fill(
                child: _GuestOverlay(
                  title: info,
                  body: DeliveryCopy.readOnPhone(
                    _shortAddress(
                      info == DeliveryCopy.privacyTitle
                          ? widget.terms.privacyUrl
                          : widget.terms.termsUrl,
                    ),
                  ),
                  note: DeliveryCopy.help(widget.terms.supportContact),
                  actions: [
                    PorcelainButton(
                      label: DeliveryCopy.close,
                      size: PorcelainButtonSize.large,
                      onPressed: () => _touch(() => _info = null),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      _Step.result => _Result(
        failed: _failed,
        offline: widget.offline,
        masked: _sentTo?.masked ?? '',
        intent: _intentId == null ? null : widget.watch(_intentId!),
        onDone: widget.onFinish,
      ),
    };
  }

  static String _shortAddress(String url) =>
      url.replaceFirst(RegExp('^https://'), '').replaceFirst(RegExp(r'/$'), '');
}

/// S31 Phone and consent (UX-PD2, UX-PD7): the photo beside (landscape)
/// or above (portrait) the number, a large keypad, the unchecked consent
/// and Send, which waits for a valid number and the box.
class _PhoneEntry extends StatelessWidget {
  const _PhoneEntry({
    required this.photo,
    required this.aspect,
    required this.digits,
    required this.parsed,
    required this.consent,
    required this.consentText,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
    required this.onToggleConsent,
    required this.onSend,
    required this.onNoThanks,
    required this.onPrivacy,
    required this.onTerms,
  });

  final Uint8List photo;
  final double aspect;
  final String digits;
  final PhoneParse? parsed;
  final bool consent;
  final String consentText;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onToggleConsent;
  final VoidCallback onSend;
  final VoidCallback onNoThanks;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return GuestBackdrop(
      dense: true,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = GuestScale.forSize(constraints.biggest);
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final problem = parsed?.problem;
            final ready = parsed?.ok == true;
            final heading = GuestHeading(
              title: DeliveryCopy.entryTitle,
              subtitle: DeliveryCopy.entrySubtitle,
              scale: scale,
            );
            final display = _NumberDisplay(
              digits: digits,
              problem: problem,
              scale: scale,
            );
            final keypad = _Keypad(
              scale: scale,
              onDigit: onDigit,
              onDelete: digits.isEmpty ? null : onDelete,
              onClear: digits.isEmpty ? null : onClear,
            );
            final agreement = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConsentCheck(
                  checked: consent,
                  text: consentText,
                  scale: scale,
                  onToggle: onToggleConsent,
                ),
                SizedBox(height: scale(PorcelainSpace.xs)),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: scale(PorcelainSpace.md),
                  children: [
                    PorcelainButton(
                      label: DeliveryCopy.privacy,
                      icon: PorcelainIcons.privacy,
                      variant: PorcelainButtonVariant.quiet,
                      size: PorcelainButtonSize.compact,
                      onPressed: onPrivacy,
                    ),
                    PorcelainButton(
                      label: DeliveryCopy.terms,
                      icon: PorcelainIcons.info,
                      variant: PorcelainButtonVariant.quiet,
                      size: PorcelainButtonSize.compact,
                      onPressed: onTerms,
                    ),
                  ],
                ),
                SizedBox(height: scale(PorcelainSpace.lg)),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: scale(PorcelainSpace.lg),
                  runSpacing: scale(PorcelainSpace.sm),
                  children: [
                    PorcelainButton(
                      label: DeliveryCopy.noThanks,
                      size: PorcelainButtonSize.large,
                      onPressed: onNoThanks,
                    ),
                    PorcelainButton(
                      label: DeliveryCopy.sendMyPhotos,
                      icon: PorcelainIcons.send,
                      variant: PorcelainButtonVariant.primary,
                      size: PorcelainButtonSize.large,
                      disabledReason: !ready
                          ? DeliveryCopy.needNumber
                          : (!consent ? DeliveryCopy.needConsent : null),
                      onPressed: ready && consent ? onSend : null,
                    ),
                  ],
                ),
              ],
            );
            final print = _SmallPrint(
              photo: photo,
              aspect: aspect,
              maxWidth: landscape
                  ? constraints.maxWidth * 0.3
                  : constraints.maxWidth * 0.24,
              maxHeight: landscape
                  ? constraints.maxHeight * 0.62
                  : constraints.maxHeight * 0.17,
              scale: scale,
            );
            final Widget content;
            if (landscape) {
              content = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: constraints.maxWidth * 0.32,
                    child: Center(child: print),
                  ),
                  SizedBox(width: scale(PorcelainSpace.xl)),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        heading,
                        SizedBox(height: scale(PorcelainSpace.lg)),
                        display,
                        SizedBox(height: scale(PorcelainSpace.lg)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            keypad,
                            SizedBox(width: scale(PorcelainSpace.xxl)),
                            Expanded(child: agreement),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      print,
                      SizedBox(width: scale(PorcelainSpace.xl)),
                      Expanded(child: heading),
                    ],
                  ),
                  SizedBox(height: scale(PorcelainSpace.xl)),
                  display,
                  SizedBox(height: scale(PorcelainSpace.lg)),
                  keypad,
                  SizedBox(height: scale(PorcelainSpace.xl)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: scale(620)),
                    child: agreement,
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale(PorcelainSpace.xxl),
                    vertical: scale(PorcelainSpace.lg),
                  ),
                  child: Center(
                    child: DefaultTextStyle.merge(
                      style: theme.text.guestBody,
                      child: content,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The finished photo, small, as a print (it stays visible but separate
/// from the number).
class _SmallPrint extends StatelessWidget {
  const _SmallPrint({
    required this.photo,
    required this.aspect,
    required this.maxWidth,
    required this.maxHeight,
    required this.scale,
  });

  final Uint8List photo;
  final double aspect;
  final double maxWidth;
  final double maxHeight;
  final GuestScale scale;

  @override
  Widget build(BuildContext context) {
    final border = scale(8);
    var width = maxWidth;
    var height = (width - 2 * border) / aspect + 2 * border;
    if (height > maxHeight) {
      height = maxHeight;
      width = (height - 2 * border) * aspect + 2 * border;
    }
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return ExcludeSemantics(
      child: GuestPrint(
        scale: scale,
        border: 8,
        angle: -0.04,
        child: SizedBox(
          width: width - 2 * border,
          height: height - 2 * border,
          child: Image.memory(
            photo,
            fit: BoxFit.contain,
            cacheWidth: math.max(64, ((width - 2 * border) * ratio).ceil()),
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

/// The number as it is typed, in a porcelain well, with the country and an
/// inline correction (never a raw code).
class _NumberDisplay extends StatelessWidget {
  const _NumberDisplay({
    required this.digits,
    required this.problem,
    required this.scale,
  });

  final String digits;
  final PhoneProblem? problem;
  final GuestScale scale;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final shown = formatUsDigits(digits);
    final message = switch (problem) {
      PhoneProblem.invalid => DeliveryCopy.invalid,
      PhoneProblem.regionUnsupported => DeliveryCopy.unsupported,
      null => DeliveryCopy.countryHint,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: scale(560)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            label:
                '${DeliveryCopy.numberLabel}, ${DeliveryCopy.country}: '
                '${digits.isEmpty ? 'empty' : digits.split('').join(' ')}',
            child: ExcludeSemantics(
              child: TactileSurface(
                duration: PorcelainMotion.of(context).standard,
                look: TactileLook(
                  fillTop: colors.inset,
                  fillBottom: colors.surface,
                  border: problem == null ? colors.outline : colors.danger,
                  borderWidth: problem == null ? 1 : 2,
                  inset: 0.6,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale(PorcelainSpace.xl),
                    vertical: scale(PorcelainSpace.md),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '+1',
                        style: scale.text(
                          theme.text.guestTitle.copyWith(
                            fontSize: 30,
                            color: colors.guestAccentText,
                          ),
                        ),
                      ),
                      SizedBox(width: scale(PorcelainSpace.lg)),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            shown.isEmpty
                                ? DeliveryCopy.numberPlaceholder
                                : shown,
                            maxLines: 1,
                            style: scale.text(
                              theme.text.guestTitle.copyWith(
                                fontSize: 40,
                                letterSpacing: 1,
                                color: shown.isEmpty
                                    ? colors.inkMuted
                                    : colors.ink,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: scale(PorcelainSpace.xs)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: scale.text(
              theme.text.guestCaption.copyWith(
                color: problem == null ? colors.inkMuted : colors.danger,
                fontWeight: problem == null ? null : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Twelve large porcelain keys: digits, Clear and Delete (>= 48 dp at the
/// smallest window, 80 dp on a typical tablet).
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.scale,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
  });

  final GuestScale scale;
  final ValueChanged<String> onDigit;
  final VoidCallback? onDelete;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final size = math.max(PorcelainSize.minTouchTarget + 8, scale(80));
    final gap = scale(PorcelainSpace.md);
    Widget digit(String value) => _Key(
      size: size,
      label: DeliveryCopy.digitLabel(value),
      onPressed: () => onDigit(value),
      child: Text(
        value,
        style: scale.text(
          context.porcelain.text.guestTitle.copyWith(fontSize: 32),
        ),
      ),
    );
    Widget row(List<Widget> keys) => Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, key) in keys.indexed) ...[
            if (i > 0) SizedBox(width: gap),
            key,
          ],
        ],
      ),
    );
    final colors = context.porcelain.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          _Key(
            size: size,
            label: DeliveryCopy.clear,
            quiet: true,
            onPressed: onClear,
            disabledReason: DeliveryCopy.nothingToClear,
            child: Text(
              DeliveryCopy.clear,
              style: scale.text(
                context.porcelain.text.guestCaption.copyWith(
                  color: onClear == null
                      ? colors.inkMuted
                      : colors.guestAccentText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          digit('0'),
          _Key(
            size: size,
            label: DeliveryCopy.deleteDigit,
            quiet: true,
            onPressed: onDelete,
            disabledReason: DeliveryCopy.nothingToClear,
            child: Icon(
              PorcelainIcons.backspace,
              size: scale(30),
              color: onDelete == null
                  ? colors.inkMuted
                  : colors.guestAccentText,
            ),
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.size,
    required this.label,
    required this.onPressed,
    required this.child,
    this.quiet = false,
    this.disabledReason,
  });

  final double size;
  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool quiet;

  /// Why the key does nothing now (read out when it is disabled).
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      disabledReason: disabledReason,
      builder: (context, state) {
        final TactileLook look;
        if (state.pressed) {
          look = TactileLook(
            fillTop: colors.inset,
            fillBottom: colors.inset,
            border: colors.outline,
            inset: 0.7,
            travel: 1,
          );
        } else if (quiet) {
          final clear = colors.canvas.withValues(alpha: 0);
          look = TactileLook(
            fillTop: state.hovered ? colors.selected : clear,
            fillBottom: state.hovered ? colors.selected : clear,
          );
        } else {
          look = TactileLook(
            fillTop: colors.raised,
            fillBottom: colors.raisedShade,
            border: colors.outline,
            elevation: PorcelainDepth.resting,
            highlight: 1,
          );
        }
        return TactileSurface(
          shape: TactileShape.circle,
          look: look,
          focused: state.focused,
          duration: state.pressed ? motion.press : motion.release,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

/// The consent box: unchecked until the guest checks it, the whole row
/// tappable, the full wording read out with its state.
class _ConsentCheck extends StatelessWidget {
  const _ConsentCheck({
    required this.checked,
    required this.text,
    required this.scale,
    required this.onToggle,
  });

  final bool checked;
  final String text;
  final GuestScale scale;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onToggle,
      toggled: checked,
      semanticLabel: text,
      builder: (context, state) => TactileSurface(
        duration: motion.standard,
        radius: PorcelainRadius.card,
        focused: state.focused,
        look: TactileLook(
          fillTop: checked ? colors.selected : colors.surface,
          fillBottom: checked ? colors.selected : colors.surface,
          border: checked ? colors.primaryEdge : colors.outline,
          borderWidth: checked ? 2 : 1,
        ),
        child: Padding(
          padding: EdgeInsets.all(scale(PorcelainSpace.md)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TactileSurface(
                duration: motion.standard,
                radius: 8,
                look: TactileLook(
                  fillTop: checked ? colors.primaryTop : colors.inset,
                  fillBottom: checked ? colors.primaryBottom : colors.surface,
                  border: checked ? colors.primaryEdge : colors.inkMuted,
                  borderWidth: 2,
                  inset: checked ? 0 : 0.4,
                ),
                child: SizedBox.square(
                  dimension: math.max(32, scale(40)),
                  child: checked
                      ? Icon(
                          PorcelainIcons.check,
                          size: math.max(24, scale(30)),
                          color: colors.onPrimary,
                          weight: 700,
                        )
                      : null,
                ),
              ),
              SizedBox(width: scale(PorcelainSpace.md)),
              Expanded(
                child: Text(
                  text,
                  style: scale.text(
                    theme.text.guestCaption.copyWith(color: colors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card over the screen: the number to confirm, or where to read the
/// privacy notice or terms.
class _GuestOverlay extends StatelessWidget {
  const _GuestOverlay({
    required this.title,
    required this.body,
    required this.actions,
    this.note,
    this.bodyIsNumber = false,
  });

  final String title;
  final String body;
  final String? note;
  final bool bodyIsNumber;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion.standard,
      // Read out from the first frame, while it fades in.
      builder: (context, t, child) =>
          Opacity(opacity: t, alwaysIncludeSemantics: true, child: child),
      child: ColoredBox(
        color: colors.scrim,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = GuestScale.forSize(constraints.biggest);
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(scale(PorcelainSpace.xl)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: scale(640)),
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: title,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: PorcelainRadius.dialogAll,
                        border: Border.all(color: colors.primaryEdge),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowKey,
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale(PorcelainSpace.xl),
                          vertical: scale(PorcelainSpace.xxl),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GuestHeading(title: title, scale: scale),
                            SizedBox(height: scale(PorcelainSpace.lg)),
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: scale.text(
                                bodyIsNumber
                                    ? theme.text.guestTitle.copyWith(
                                        fontSize: 40,
                                        color: colors.ink,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      )
                                    : theme.text.guestBody,
                              ),
                            ),
                            if (note case final note?) ...[
                              SizedBox(height: scale(PorcelainSpace.sm)),
                              Text(
                                note,
                                textAlign: TextAlign.center,
                                style: scale.text(theme.text.guestCaption),
                              ),
                            ],
                            SizedBox(height: scale(PorcelainSpace.xxl)),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: scale(PorcelainSpace.lg),
                              runSpacing: scale(PorcelainSpace.md),
                              children: actions,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// S32 (UX-PD3): what happened, in words that never overclaim, the masked
/// number, that the photo is saved, and Done. The guest is never asked to
/// wait for the text.
class _Result extends StatelessWidget {
  const _Result({
    required this.failed,
    required this.offline,
    required this.masked,
    required this.intent,
    required this.onDone,
  });

  final bool failed;
  final bool offline;
  final String masked;
  final Stream<DeliveryIntent?>? intent;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (failed || intent == null) {
      return _notice(
        context,
        title: "We couldn't send your text",
        body: DeliveryCopy.photoSaved,
        icon: PorcelainIcons.warning,
      );
    }
    return StreamBuilder<DeliveryIntent?>(
      stream: intent,
      builder: (context, snapshot) {
        final current = snapshot.data;
        if (current == null) {
          return _notice(
            context,
            title: 'Sending your photos…',
            body: DeliveryCopy.photoSaved,
            busy: true,
          );
        }
        final (title, body) = DeliveryCopy.result(current, offline: offline);
        final phase = current.phase;
        final busy =
            phase == DeliveryPhase.uploading ||
            phase == DeliveryPhase.sending ||
            (phase == DeliveryPhase.queuedLocally &&
                current.lastErrorCode == null &&
                !offline);
        final icon = switch (phase) {
          DeliveryPhase.queuedLocally => PorcelainIcons.queued,
          DeliveryPhase.submitted || DeliveryPhase.sent => PorcelainIcons.send,
          DeliveryPhase.delivered => PorcelainIcons.delivered,
          DeliveryPhase.failed ||
          DeliveryPhase.expired ||
          DeliveryPhase.unknown => PorcelainIcons.warning,
          _ => PorcelainIcons.textMessage,
        };
        return _notice(
          context,
          title: title,
          body: [
            if (body.isNotEmpty) body,
            DeliveryCopy.sentTo(masked),
            DeliveryCopy.photoSaved,
          ].join('\n'),
          icon: icon,
          busy: busy,
        );
      },
    );
  }

  Widget _notice(
    BuildContext context, {
    required String title,
    required String body,
    IconData? icon,
    bool busy = false,
  }) => GuestNotice(
    title: title,
    body: body,
    icon: icon,
    busy: busy,
    actions: [
      PorcelainButton(
        label: DeliveryCopy.done,
        icon: PorcelainIcons.nextGuest,
        variant: PorcelainButtonVariant.primary,
        size: PorcelainButtonSize.guest,
        caps: true,
        onPressed: onDone,
      ),
    ],
  );
}
