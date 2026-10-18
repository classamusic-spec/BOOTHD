import '../template_document.dart';

/// Undo and redo over immutable document snapshots (A-08, AC-0506).
///
/// Documents are small (at most 200 layers), so each step keeps a whole
/// document, capped at [limit] steps. A gesture (a drag, a pinch, a slider)
/// updates the document many times but becomes one step: [beginGesture],
/// any number of [commit]s, then [endGesture].
final class EditHistory {
  EditHistory(TemplateDocument document, {this.limit = 100})
    : _current = document,
      _saved = document;

  final int limit;
  final _undo = <TemplateDocument>[];
  final _redo = <TemplateDocument>[];
  TemplateDocument _current;
  TemplateDocument _saved;
  TemplateDocument? _gestureStart;
  var _version = 0;

  TemplateDocument get current => _current;

  /// Counts changes to [current]; a cheap way to notice an edit.
  int get version => _version;

  bool get inGesture => _gestureStart != null;
  bool get canUndo => !inGesture && _undo.isNotEmpty;
  bool get canRedo => !inGesture && _redo.isNotEmpty;

  /// Whether [current] differs from the last [markSaved] document.
  bool get hasUnsavedChanges => _current != _saved;

  /// Makes [next] the current document: one undo step, or part of the
  /// gesture in progress.
  void commit(TemplateDocument next) {
    if (next == _current) return;
    if (!inGesture) _push(_current);
    _current = next;
    _version++;
  }

  void beginGesture() => _gestureStart ??= _current;

  /// Ends the gesture as one undo step (none if nothing changed).
  void endGesture() {
    final start = _gestureStart;
    if (start == null) return;
    _gestureStart = null;
    if (start != _current) _push(start);
  }

  /// Puts the document back as it was when the gesture began.
  void cancelGesture() {
    final start = _gestureStart;
    if (start == null) return;
    _gestureStart = null;
    if (start != _current) {
      _current = start;
      _version++;
    }
  }

  TemplateDocument? undo() {
    if (!canUndo) return null;
    _redo.add(_current);
    _current = _undo.removeLast();
    _version++;
    return _current;
  }

  TemplateDocument? redo() {
    if (!canRedo) return null;
    _undo.add(_current);
    _current = _redo.removeLast();
    _version++;
    return _current;
  }

  /// Records [document] as saved (by default the current one).
  void markSaved([TemplateDocument? document]) {
    _saved = document ?? _current;
  }

  /// Starts over from [document] with no history (a restored draft keeps
  /// [saved] as its saved state, so it still counts as unsaved).
  void reset(TemplateDocument document, {TemplateDocument? saved}) {
    _undo.clear();
    _redo.clear();
    _gestureStart = null;
    _current = document;
    _saved = saved ?? document;
    _version++;
  }

  void _push(TemplateDocument document) {
    _undo.add(document);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }
}
