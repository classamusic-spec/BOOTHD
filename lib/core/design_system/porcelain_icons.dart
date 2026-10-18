import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The one icon family (CR-001 item 8): Material Symbols Rounded, Apache
/// 2.0 (`docs/ASSET_PROVENANCE.md`). Its variable weight, fill and grade
/// axes give one consistent stroke at every size.
///
/// Features use these semantic names only; the architecture test keeps the
/// icon package out of feature and shared code, so the family can be
/// swapped here without touching screens.
abstract final class PorcelainIcons {
  // Studio sections.
  static const IconData dashboard = Symbols.space_dashboard_rounded;
  static const IconData events = Symbols.calendar_month_rounded;
  static const IconData templates = Symbols.auto_awesome_mosaic_rounded;
  static const IconData gallery = Symbols.photo_library_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData diagnostics = Symbols.monitor_heart_rounded;

  // Status and devices.
  static const IconData camera = Symbols.photo_camera_rounded;
  static const IconData storage = Symbols.storage_rounded;
  static const IconData fileWrite = Symbols.save_as_rounded;
  static const IconData preflight = Symbols.checklist_rounded;
  static const IconData tablet = Symbols.tablet_rounded;
  static const IconData orientation = Symbols.screen_rotation_rounded;
  static const IconData textSize = Symbols.format_size_rounded;
  static const IconData printer = Symbols.print_rounded;
  static const IconData printerOff = Symbols.print_disabled_rounded;
  static const IconData outputFormat = Symbols.aspect_ratio_rounded;
  static const IconData portrait = Symbols.crop_portrait_rounded;
  static const IconData landscape = Symbols.crop_landscape_rounded;
  static const IconData square = Symbols.crop_square_rounded;
  static const IconData security = Symbols.shield_lock_rounded;
  static const IconData appearance = Symbols.palette_rounded;
  static const IconData contrast = Symbols.contrast_rounded;
  static const IconData motion = Symbols.animation_rounded;
  static const IconData licence = Symbols.license_rounded;
  static const IconData privacy = Symbols.lock_rounded;

  // Lifecycle filters.
  static const IconData active = Symbols.celebration_rounded;
  static const IconData draft = Symbols.edit_note_rounded;
  static const IconData archive = Symbols.archive_rounded;

  // Actions.
  static const IconData add = Symbols.add_rounded;
  static const IconData remove = Symbols.remove_rounded;
  static const IconData start = Symbols.play_arrow_rounded;
  static const IconData preview = Symbols.visibility_rounded;
  static const IconData import = Symbols.file_open_rounded;
  static const IconData export = Symbols.file_export_rounded;
  static const IconData search = Symbols.search_rounded;
  static const IconData retry = Symbols.refresh_rounded;
  static const IconData expand = Symbols.open_in_full_rounded;
  static const IconData back = Symbols.arrow_back_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData backspace = Symbols.backspace_rounded;
  static const IconData moveUp = Symbols.arrow_upward_rounded;
  static const IconData moveDown = Symbols.arrow_downward_rounded;
  static const IconData duplicate = Symbols.content_copy_rounded;
  static const IconData edit = Symbols.edit_rounded;
  static const IconData restore = Symbols.unarchive_rounded;
  static const IconData lockNow = Symbols.lock_person_rounded;
  static const IconData chevron = Symbols.chevron_right_rounded;
  static const IconData check = Symbols.check_rounded;

  // Tones.
  static const IconData info = Symbols.info_rounded;
  static const IconData success = Symbols.check_circle_rounded;
  static const IconData warning = Symbols.warning_rounded;
  static const IconData error = Symbols.error_rounded;
  static const IconData pending = Symbols.pending_rounded;
  static const IconData locked = Symbols.lock_rounded;
  static const IconData busy = Symbols.hourglass_top_rounded;

  // Developer tools.
  static const IconData code = Symbols.code_rounded;
  static const IconData layers = Symbols.layers_rounded;
  static const IconData components = Symbols.widgets_rounded;
}
