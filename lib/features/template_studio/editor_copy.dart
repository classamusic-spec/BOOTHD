import '../../core/templates/template_library.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/template/editing/document_edits.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';
import '../../shared/templates/template_messages.dart';
import 'editor_controller.dart';

/// Template Studio wording (S06 to S12), kept out of the widgets.
abstract final class EditorCopy {
  static String refusal(Object error) => switch (error) {
    EditRefused(:final reason) => switch (reason) {
      EditRefusal.tooManyLayers =>
        'A template can have at most ${TemplateDocument.maxLayers} layers.',
      EditRefusal.tooManySlots =>
        'A template can have at most ${PhotoSlotLayer.maxSlots} photos.',
      EditRefusal.notFound => 'That layer is no longer in the template.',
      EditRefusal.locked => 'Unlock the layer first.',
      EditRefusal.backgroundFixed =>
        'The background always stays at the bottom, and there is one.',
    },
    InvalidEdit(:final issues) =>
      issues.isEmpty
          ? 'That change would break the template.'
          : "That change can't be made: ${issues.first.message}",
    TemplateStoreException() => storeError(error),
    _ => "That didn't work. Try again.",
  };

  static String storeError(TemplateStoreException error) =>
      TemplateMessages.storeError(error);

  static String pickError(FilePickException error) =>
      TemplateMessages.pickError(error);

  static String draftState(DraftState state, {required bool saving}) {
    if (saving) return 'Saving…';
    return switch (state) {
      DraftState.clean => 'All changes saved',
      DraftState.pending || DraftState.writing => 'Unsaved changes',
      DraftState.written => 'Unsaved · draft kept',
      DraftState.failed => "Unsaved · draft couldn't be kept",
    };
  }

  static String saved(int revision) => 'Saved as revision $revision.';

  static const fileNameLimit = maxTemplateNameLength;
}
