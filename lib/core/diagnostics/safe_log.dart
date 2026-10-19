import 'package:flutter/foundation.dart';

/// The app's only way to write to the device log (AC-1007, ADR-0016).
///
/// Nothing else in `lib/` prints (test/architecture/logging_test.dart holds
/// that). Every line passes through [sanitize] first: anyone with the
/// tablet and a cable can read the device log, so it never carries photo
/// data, file paths or names, phone numbers, e-mail addresses, links or
/// tokens. Errors are logged by type and cleaned message, stack traces only
/// in debug builds. IDs (UUIDs) and timestamps stay readable: support
/// works from them and they identify no one.
abstract final class SafeLog {
  /// Where lines go: `debugPrint` unless a test captures them.
  @visibleForTesting
  static void Function(String line) sink = _print;

  static void _print(String line) => debugPrint(line);

  /// Logs one event: a short fixed [what] written in the source (a code or
  /// a sentence, never guest data) and an optional [detail].
  static void event(String what, [String detail = '']) => sink(
    'porcelain: ${sanitize(what)}'
    '${detail.isEmpty ? '' : ': ${sanitize(detail)}'}',
  );

  /// Logs an error that reached the top: its type and cleaned message.
  static void error(Object error, StackTrace? stack, {String? context}) {
    final where = context == null ? '' : ' (${sanitize(context)})';
    sink(
      'porcelain: error$where: ${error.runtimeType}: '
      '${sanitize(_message(error))}',
    );
    final trace = stack?.toString() ?? '';
    if (kDebugMode && trace.isNotEmpty) {
      sink(sanitize(trace, maxLength: 4000));
    }
  }

  static String _message(Object error) {
    try {
      return error.toString();
    } on Object {
      return '(unprintable)';
    }
  }

  /// Kept as they are: random IDs and dates, whose digit runs would
  /// otherwise read as phone numbers.
  static final _kept = [
    RegExp(
      r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
      caseSensitive: false,
    ),
    RegExp(r'\b\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?Z?)?'),
  ];

  static final _rules = <(RegExp, String Function(Match))>[
    // Inline image or file data.
    (RegExp(r'data:[\w/+.-]+;base64,[A-Za-z0-9+/=]+'), (_) => '<data>'),
    // Links keep their host only: paths and queries carry tokens.
    (
      RegExp(
        r'\b(https?)://([A-Za-z0-9.-]+)(?::\d+)?[^\s"'
        "'"
        r')>\]]*',
      ),
      (match) => '${match[1]}://${match[2]}/<…>',
    ),
    // File URIs and absolute paths: app containers name the device's user
    // and file names can name a guest.
    (
      RegExp(
        r'file://[^\s"'
        "'"
        r')>\]]+',
      ),
      (_) => '<path>',
    ),
    (
      RegExp(
        r'(?:(?<=[\s='
        "'"
        r'"(:])|^)/(?:[^\s"'
        "'"
        r'()<>/]+/)+'
        r'[^\s"'
        "'"
        r'()<>,;]*',
      ),
      (_) => '<path>',
    ),
    // Bare file names of photos, packages, backups and databases.
    (
      RegExp(
        r'[^\s/\\"'
        "'"
        r'()<>:]+\.(?:jpe?g|png|heic|heif|webp|gif|tar|zip|'
        r'porcelain|json|sqlite|db)\b',
        caseSensitive: false,
      ),
      (_) => '<file>',
    ),
    // E-mail addresses.
    (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), (_) => '<email>'),
    // Phone numbers and other long numbers. A number never starts or ends
    // inside a word.
    (
      RegExp(r'(?<![0-9A-Za-z])\+?\(?\d[\d ().-]{5,}\d(?![0-9A-Za-z])'),
      (_) => '<number>',
    ),
    // Digests and tokens: long hex, base64 and base64url runs.
    (RegExp(r'\b[A-Fa-f0-9]{24,}\b'), (_) => '<hex>'),
    (RegExp(r'[A-Za-z0-9_-]{40,}={0,2}'), (_) => '<token>'),
    (RegExp(r'[A-Za-z0-9+/]{40,}={0,2}'), (_) => '<token>'),
  ];

  /// [text] without anything that could identify a guest, a file or a
  /// secret, cut to [maxLength] characters.
  static String sanitize(String text, {int maxLength = 600}) {
    final kept = <String>[];
    var clean = text;
    for (final pattern in _kept) {
      clean = clean.replaceAllMapped(pattern, (match) {
        kept.add(match[0]!);
        return '${kept.length - 1}';
      });
    }
    for (final (pattern, replace) in _rules) {
      clean = clean.replaceAllMapped(pattern, replace);
    }
    clean = clean.replaceAllMapped(
      RegExp('(\\d+)'),
      (match) => kept[int.parse(match[1]!)],
    );
    return clean.length <= maxLength
        ? clean
        : '${clean.substring(0, maxLength)}…';
  }
}
