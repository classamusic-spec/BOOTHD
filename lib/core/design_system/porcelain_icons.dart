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

  // The guest welcome's step guide (CR-002).
  static const IconData pose = Symbols.person_rounded;
  static const IconData smile = Symbols.sentiment_satisfied_rounded;
  static const IconData enjoy = Symbols.favorite_rounded;

  // Guest sessions (S21 to S29).
  static const IconData retake = Symbols.replay_rounded;
  static const IconData nextGuest = Symbols.arrow_forward_rounded;
  static const IconData paused = Symbols.pause_circle_rounded;

  // Template Studio (S07 to S12).
  static const IconData selectTool = Symbols.arrow_selector_tool_rounded;
  static const IconData panTool = Symbols.pan_tool_rounded;
  static const IconData background = Symbols.format_paint_rounded;
  static const IconData photoSlot = Symbols.add_a_photo_rounded;
  static const IconData image = Symbols.image_rounded;
  static const IconData text = Symbols.title_rounded;
  static const IconData shape = Symbols.category_rounded;
  static const IconData rectangle = Symbols.rectangle_rounded;
  static const IconData roundedRectangle = Symbols.rounded_corner_rounded;
  static const IconData ellipse = Symbols.circle_rounded;
  static const IconData decorations = Symbols.local_florist_rounded;
  static const IconData inspector = Symbols.tune_rounded;
  static const IconData undo = Symbols.undo_rounded;
  static const IconData redo = Symbols.redo_rounded;
  static const IconData zoomIn = Symbols.zoom_in_rounded;
  static const IconData zoomOut = Symbols.zoom_out_rounded;
  static const IconData fitScreen = Symbols.fit_screen_rounded;
  static const IconData grid = Symbols.grid_4x4_rounded;
  static const IconData snap = Symbols.straighten_rounded;
  static const IconData safeArea = Symbols.crop_free_rounded;
  static const IconData save = Symbols.save_rounded;
  static const IconData visible = Symbols.visibility_rounded;
  static const IconData hidden = Symbols.visibility_off_rounded;
  static const IconData unlocked = Symbols.lock_open_rounded;
  static const IconData delete = Symbols.delete_rounded;
  static const IconData bringForward = Symbols.flip_to_front_rounded;
  static const IconData sendBackward = Symbols.flip_to_back_rounded;
  static const IconData bringToFront = Symbols.vertical_align_top_rounded;
  static const IconData sendToBack = Symbols.vertical_align_bottom_rounded;
  static const IconData more = Symbols.more_horiz_rounded;
  static const IconData dragHandle = Symbols.drag_indicator_rounded;
  static const IconData rename = Symbols.drive_file_rename_outline_rounded;
  static const IconData share = Symbols.ios_share_rounded;
  static const IconData upload = Symbols.upload_file_rounded;
  static const IconData alignLeft = Symbols.format_align_left_rounded;
  static const IconData alignCenter = Symbols.format_align_center_rounded;
  static const IconData alignRight = Symbols.format_align_right_rounded;
  static const IconData alignTop = Symbols.vertical_align_top_rounded;
  static const IconData alignMiddle = Symbols.vertical_align_center_rounded;
  static const IconData alignBottom = Symbols.vertical_align_bottom_rounded;
  static const IconData transparent = Symbols.texture_rounded;
}
