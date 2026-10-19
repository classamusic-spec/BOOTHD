# Kiosk deployment: keeping guests inside the booth (M10)

The booth app keeps guests on its own screens (Booth Mode: no Studio, no
gallery, no share sheet, no platform dialogs; the operator leaves with a
hidden three-second hold and the PIN). **It cannot stop someone leaving
the app itself**: the Home gesture, the app switcher, notifications and
the power button belong to the operating system. Only the tablet's own
kiosk features can lock a tablet to one app, and the app never turns one
on or off or says it can. What it does: Settings > Kiosk lock shows
whether the tablet reports a lock, with the steps below for its platform,
and the launch checks warn until the tablet reports one (section 5).

Pick one method per tablet before an event and test it with the steps in
section 4.

## 1. iPad

| | Guided Access | Single App Mode (supervised) |
| --- | --- | --- |
| What it is | A built-in accessibility feature that locks the iPad to the app in front until the passcode is entered | A configuration profile that keeps the iPad in one app, even after a restart |
| Needs | Any iPad; nothing to install | The iPad supervised (Apple Configurator on a Mac, or Apple Business Manager with a device management service); a profile naming the app's bundle ID |
| Turn on | Settings > Accessibility > Guided Access: on; set a passcode (and Face ID or Touch ID if you like); open the booth and triple-click the top (or Home) button; Start | Prepare the iPad as supervised (this erases it), then install a Single App Mode profile for Porcelain Photo Booth from the management tool |
| Turn off | Triple-click, enter the Guided Access passcode, End | Remove the profile from the management tool |
| After a restart or crash | The lock is gone: the operator must start Guided Access again | The iPad starts straight into the app |
| Good for | Single events run by the owner | Rental fleets, unattended or long installations |
| Cautions | Use a Guided Access passcode different from the booth PIN. Turn off Time Limits. In Options, leave Touch on and Keyboards off | Updates and support need the management tool; the iPad cannot be used for anything else while the profile is on |

Also on iPad:

- **Full screen and orientation.** With Stage Manager or Split View on,
  iPadOS may show the booth in a window and ignore its orientation
  preference (ADR-0004). Turn off Stage Manager (Control Center) and do
  not open a second app beside it. The launch checks warn when the
  tablet's actual shape does not match the event's orientation.
- **Auto-Lock.** Settings > Display & Brightness > Auto-Lock: Never, on
  continuous power (the booth does not hold the screen awake itself in
  this release).
- **Notifications.** Turn on a Focus (Do Not Disturb) for the event so
  banners do not cover the guest screens.
- Autonomous Single App Mode (where an app starts and ends the lock
  itself) is not used: it needs a management profile that allows it and
  native code the release does not include.

## 2. Android tablets

| | App pinning (screen pinning) | Lock task mode (managed, "kiosk mode") |
| --- | --- | --- |
| What it is | A built-in feature that pins the app in front; leaving needs a gesture and the device PIN | The device policy controller of a fully managed tablet keeps it in allowed apps only |
| Needs | Any Android tablet with a screen lock | The tablet enrolled as fully managed (device owner) with an enterprise mobility management service (for example Android Enterprise with a kiosk policy), Porcelain Photo Booth allowed for lock task |
| Turn on | Settings > Security (or Security & privacy > More security settings) > App pinning: on, with "Ask for PIN before unpinning"; open Recents, tap the booth's icon, Pin | Enrolment usually needs a factory reset and a QR code or zero-touch; then apply a single-app kiosk policy |
| Turn off | Back and Overview held together (or the gesture the tablet shows), then the device PIN | Change the policy in the management console |
| After a restart or crash | Unpinned: pin again | The management service starts the app in lock task again |
| Good for | Single events run by the owner | Rental fleets and long installations |
| Cautions | The names of the settings differ between manufacturers. Notifications can still appear: turn on Do Not Disturb. Some tablets let a long press on the navigation bar unpin without a PIN if "Ask for PIN" is off | The status bar, notifications and system dialogs are controlled by the policy; test that the camera permission prompt is not blocked before the event |

Also on Android:

- **Orientation on large screens.** Android 16 and later may ignore an
  app's orientation request on tablets (600 dp and wider), and Android 17
  removes the opt-out. The booth adapts to the tablet's actual shape and
  warns when the event's orientation cannot be kept (ADR-0004). Use the
  tablet's rotation lock in the orientation you want.
- **Battery optimisation and sleep.** Settings > Display > Screen timeout:
  the longest; keep the tablet on power.
- The release does not call `startLockTask` itself: without a device
  owner it would only ask the guest to pin, which is the same as app
  pinning, and with one the management service starts lock task.

## 3. What the booth adds on top of the lock

- Booth Mode shows guests only the welcome, camera, review, finished and
  (when turned on) texting screens; deep links, the back gesture and
  system back are refused (AC-0706, AC-0922).
- The operator's exit is a three-second hold in a corner, then the PIN,
  with rate limiting after wrong tries (ADR-0009).
- After a crash or restart the booth reopens on the welcome screen, never
  on a previous guest's photos (M07, M10 tests).

## 4. Test before guests arrive (each tablet)

1. Turn on the lock (section 1 or 2).
2. Start Booth Mode from the launch checks.
3. Try to leave: Home gesture, app switcher, notification shade, control
   center, power button short press, rotate. The booth must stay in front
   (or come straight back), and no other app may open.
4. Do a full guest session, including texting if the event uses it.
5. Leave with the hidden hold and the PIN; turn off the lock with its own
   passcode.
6. Record the tablet, OS version, method and result in the event log.

## 5. What the app can see, and what it cannot

The app reads the lock through a small read-only bridge (ADR-0016): one
method that reports a state, and nothing that starts or stops a lock
(a test checks the native code for that).

| Tablet reports | Settings > Kiosk lock | Launch check |
| --- | --- | --- |
| iPadOS: Guided Access is on (`UIAccessibility.isGuidedAccessEnabled`) | Locked to the booth app | Passed |
| Android: lock task mode from a device policy controller (`getLockTaskModeState` = locked) | Locked by device management | Passed |
| Android: app pinning (`getLockTaskModeState` = pinned) | Pinned to the booth app, with a reminder about "Ask for PIN before unpinning" | Passed |
| No lock | Guests can leave the booth app | Warning: how to lock it |
| The tablet did not answer | The tablet didn't say | Warning |

What it cannot see, so the operator checks it with section 4:

- Whether "Ask for PIN before unpinning" is on (Android), the Guided
  Access options chosen (iPad), or whether notifications can still
  appear.
- iPadOS is expected to report Single App Mode the same way as Guided
  Access; this is verified on a supervised iPad in M11 (until then, a
  Single App Mode iPad that shows "Guests can leave the booth app" is a
  known open question, not a lock failure: test it with section 4).

The kiosk check never blocks a launch: the lock is the operator's to set,
and an event can run without one (for example with a staffed booth).
