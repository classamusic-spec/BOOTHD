/// The building blocks an Experience Pack may name (EP01, ADR-0017). A pack
/// is data: it chooses among these predefined presets and bundled assets
/// and can never name code, a URL or a file of its own. The presentation
/// layer has one implementation per id; a test keeps the two in step.
library;

/// Guest button presentations; one semantic button, six looks.
enum GuestButtonStyle { porcelain, wood, toyArcade, retroGame, gala, neonParty }

/// How much decorative motion guests see. Reduced-motion settings on the
/// tablet or booth always win and mean [off].
enum AnimationIntensity { off, gentle, full }

/// How the camera screen shows the selected photo template (EP06).
enum CameraStageMode {
  /// The template drawn around the live picture in its photo space.
  fullTemplate,

  /// The live picture large, the template as a small guide.
  cameraFocused,
}

/// The two guest layouts every pack supports.
enum ExperienceOrientation { portrait, landscape }

/// Moments that may play a sound.
enum SoundCue { press, start, tick, go, shutter, success, celebrate }

/// What an operator may change in an event's experience.
enum ExperienceSetting {
  variant,
  accentColor,
  welcomeText,
  getReadyText,
  finishText,
  countdown,
  sound,
  animation,
  celebration,
  cameraStage,
}

/// The ids each preset kind may take.
abstract final class ExperienceCatalog {
  static const countdowns = {
    'porcelain-press',
    'vintage-flip',
    'film-leader',
    'disco-pulse',
    'storybook-magic',
    'party-pop',
    'arcade-start',
    'handheld-boot',
    'gala-elegant',
  };

  static const transitions = {
    'fade',
    'rise',
    'curtain',
    'iris',
    'pop',
    'pixel-wipe',
    'page-turn',
  };

  /// Gentle shutter acknowledgements: none flashes more than once.
  static const shutters = {
    'soft-glow',
    'film-wink',
    'pixel-blink',
    'pop-ring',
    'gold-shimmer',
  };

  static const celebrations = {
    'none',
    'confetti',
    'sparkles',
    'petals',
    'pixel-stars',
    'gold-dust',
    'neon-rings',
  };

  static const layouts = {
    'porcelain-stage',
    'wood-cabinet',
    'film-strip',
    'neon-floor',
    'garden-arch',
    'deco-frame',
    'party-burst',
    'handheld-console',
    'arcade-cabinet',
  };

  /// Bundled guest decorations (generated in-repo, ASSET_PROVENANCE.md).
  static const decorations = {
    'floral-spray',
    'brass-corners',
    'film-perforations',
    'disco-glints',
    'garden-blooms',
    'garden-bees',
    'deco-fans',
    'party-balloons',
    'party-confetti',
    'party-stars',
    'pixel-hearts',
    'pixel-coins',
    'console-dpad',
    'arcade-marquee',
  };

  static const sounds = {
    'porcelain-tap',
    'porcelain-chime',
    'wood-click',
    'film-tick',
    'disco-pulse',
    'garden-twinkle',
    'gala-bell',
    'toy-press',
    'soft-pop',
    'cheer-confirm',
    'party-chime',
    'arcade-start',
    'select-beep',
    'countdown-tick',
    'level-complete',
    'shutter-soft',
  };

  /// Bundled font families (OFL, ASSET_PROVENANCE.md).
  static const fonts = {
    'inter',
    'cormorant',
    'courier-prime',
    'monoton',
    'fredoka',
    'poiret-one',
    'pixelify-sans',
  };
}
