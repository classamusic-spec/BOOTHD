import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../core/templates/template_library.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/operator_files.dart';
import '../../shared/templates/template_messages.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/tone.dart';
import 'new_template_sheet.dart';

/// The library's actions (S06, S12), with their confirmations and
/// results. Each reports the outcome in plain words; nothing claims
/// success before the store has it.
abstract final class LibraryActions {
  /// Packages are at most this large (the package reader's own limit).
  static const maxPackageBytes = 100 * 1024 * 1024;

  static void _toast(
    BuildContext context,
    String message, {
    PorcelainTone tone = PorcelainTone.info,
  }) {
    if (context.mounted) PorcelainToast.show(context, message, tone: tone);
  }

  static Future<void> create(BuildContext context, WidgetRef ref) async {
    final choice = await chooseNewTemplate(context);
    if (choice == null || !context.mounted) return;
    try {
      final created = await ref
          .read(templateLibraryProvider)
          .create(choice.design, name: choice.name);
      if (context.mounted) {
        context.go(RoutePaths.templateEditor(created.templateId));
      }
    } on TemplateStoreException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          TemplateMessages.storeError(error),
          tone: PorcelainTone.danger,
        );
      }
    }
  }

  static Future<void> import(BuildContext context, WidgetRef ref) async {
    final PickedFile? file;
    try {
      file = await ref
          .read(operatorFilesProvider)
          .pick(PickableFile.templatePackage, maxBytes: maxPackageBytes);
    } on FilePickException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          TemplateMessages.pickError(error),
          tone: PorcelainTone.danger,
        );
      }
      return;
    }
    if (file == null) return;
    try {
      // Checked completely before anything is stored (S12).
      final imported = await ref
          .read(templateLibraryProvider)
          .importPackage(file.bytes);
      if (context.mounted) {
        _toast(
          context,
          'Imported "${imported.templateName}".',
          tone: PorcelainTone.success,
        );
      }
    } on TemplateStoreException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          '${TemplateMessages.storeError(error)} Nothing was imported.',
          tone: PorcelainTone.danger,
        );
      }
    }
  }

  static Future<void> export(
    BuildContext context,
    WidgetRef ref,
    TemplateListing template, {
    required Rect anchor,
  }) async {
    try {
      final package = await ref
          .read(templateLibraryProvider)
          .exportPackage(template.latest);
      final outcome = await ref
          .read(operatorFilesProvider)
          .share(
            package.bytes,
            fileName: package.fileName,
            mimeType: templatePackageMimeType,
            anchor: (
              left: anchor.left,
              top: anchor.top,
              width: anchor.width,
              height: anchor.height,
            ),
          );
      if (context.mounted && outcome == ShareOutcome.shared) {
        _toast(context, 'Sent "${package.fileName}".');
      }
    } on TemplateStoreException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          TemplateMessages.storeError(error),
          tone: PorcelainTone.danger,
        );
      }
    } on Exception {
      if (context.mounted) {
        _toast(
          context,
          "The share sheet couldn't open. Try again.",
          tone: PorcelainTone.danger,
        );
      }
    }
  }

  static Future<void> duplicate(
    BuildContext context,
    WidgetRef ref,
    TemplateListing template,
  ) async {
    try {
      final copy = await ref
          .read(templateLibraryProvider)
          .duplicate(
            template.latest.revisionId,
            name: TemplateLibrary.copyName(template.latest.templateName),
          );
      if (context.mounted) {
        _toast(
          context,
          'Made "${copy.templateName}".',
          tone: PorcelainTone.success,
        );
      }
    } on TemplateStoreException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          TemplateMessages.storeError(error),
          tone: PorcelainTone.danger,
        );
      }
    }
  }

  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    TemplateListing template,
  ) async {
    final controller = TextEditingController(
      text: template.latest.templateName,
    );
    final name = await showPorcelainSheet<String>(
      context: context,
      title: 'Rename template',
      body: PorcelainTextField(
        label: 'Name',
        controller: controller,
        maxLength: maxTemplateNameLength,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Cancel',
          variant: PorcelainButtonVariant.quiet,
          onPressed: () => Navigator.of(sheet).pop(),
        ),
        PorcelainButton(
          label: 'Rename',
          variant: PorcelainButtonVariant.primary,
          onPressed: () => Navigator.of(sheet).pop(controller.text),
        ),
      ],
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      await ref.read(templateLibraryProvider).rename(template.templateId, name);
    } on TemplateStoreException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          TemplateMessages.storeError(error),
          tone: PorcelainTone.warning,
        );
      }
    }
  }

  static Future<void> setArchived(
    BuildContext context,
    WidgetRef ref,
    TemplateListing template, {
    required bool archived,
  }) async {
    if (archived) {
      final events = template.eventCount;
      final confirmed = await showPorcelainSheet<bool>(
        context: context,
        title: 'Archive "${template.latest.templateName}"?',
        body: Text(
          events == 0
              ? 'It leaves the library list and cannot be added to events. '
                    'You can restore it at any time.'
              : 'The ${events == 1 ? 'event' : '$events events'} that offer '
                    'it keep it. It cannot be added to other events until '
                    'you restore it.',
        ),
        actions: (sheet) => [
          PorcelainButton(
            label: 'Keep it',
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
          PorcelainButton(
            label: 'Archive',
            icon: PorcelainIcons.archive,
            variant: PorcelainButtonVariant.danger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
        ],
      );
      if (confirmed != true || !context.mounted) return;
    }
    try {
      await ref
          .read(templateLibraryProvider)
          .setArchived(template.templateId, archived: archived);
    } on TemplateStoreException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          TemplateMessages.storeError(error),
          tone: PorcelainTone.danger,
        );
      }
    }
  }
}
