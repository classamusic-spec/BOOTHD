# Operator guide: privacy, data, retention and deletion (M10)

What the booth keeps, where, for how long, and how to remove it. For the
operator and anyone reviewing the booth for a venue or a client. Optional
texting has its own draft for legal review
(`docs/delivery/PRIVACY_AND_RETENTION_DRAFT.md`).

## 1. What the booth keeps

| Data | Where | Who can see it |
| --- | --- | --- |
| Camera photos (originals), every attempt including retakes | The app's private storage on the tablet | The operator, in Studio > Gallery |
| Finished photos (the print layout) | The app's private storage | The operator; the guest on the finished screen |
| Event settings, templates, images uploaded for templates | The app's database and private storage | The operator |
| Session records (times, outcome, which photos were used) | The app's database | The operator |
| Export history (when files were handed to the share sheet, how many, file names) | The app's database | The operator |
| Operator PIN | A slow salted verifier in the platform's secure storage (Keychain or Android Keystore), never the PIN itself | Nobody |
| Recovery code | A slow salted verifier in the database | Nobody |
| Texting (only if set up): pending phone numbers, the booth's credential | Platform secure storage; the database keeps the last four digits | The operator sees the last four digits |

The booth sends nothing anywhere unless texting is set up and a guest
asks for a text. It has no analytics, no advertising and no crash
reporting service. Its device log lines are sanitized: no photo data,
file paths or names, phone numbers, e-mail addresses, links or tokens
(AC-1007).

None of it is in the tablet's own backups: Android keeps app data out of
cloud backup and device transfer, and on iPad the booth marks its storage
excluded from iCloud and computer backups at every start. The booth's own
backup (section 5) is the way to move a booth.

The app asks for one permission that needs the operator's yes, the
camera. On Android it also declares network access, used only for
optional texting; it records no audio, reads no shared storage and asks
for nothing else (checked on every release build).

## 2. What guests are told

- The welcome screen shows the event's own text; set it in Event >
  Experience. Tell guests, in words that suit the event, that photos are
  kept by the host.
- Event > Privacy holds the "Privacy note for guests" and the retention
  rule (below); write the note before the event. It is not legal advice.
- With texting on, the consent screen is shown before any text
  (Event > Texting shows the exact words, with an export for review).

## 3. Retention

Each event has a retention rule (Event > Privacy > Keeping photos):

- **Until an operator deletes them** (default).
- **For a set time** (7, 30 or 90 days, or a year): sessions past that time are
  listed in the gallery for review; the booth never deletes them on its
  own. The operator confirms with "Delete them permanently". Archiving
  an event never deletes photos.

Exports and backups are copies outside the booth's control: whatever the
operator saved to a computer, AirDrop or a USB drive stays there until
deleted there.

## 4. Deleting

| What | How | What happens |
| --- | --- | --- |
| One or more sessions | Gallery > Select > Delete | Records removed in one step; files removed right after; an interruption finishes at the next start. Texted links are turned off |
| A whole event | Archive it, then Events > Archived > Delete | All its sessions and files, as above |
| A guest asks for their photo to be removed | Find the session (time, session number), delete it | As above. Copies already exported, printed or texted are outside the booth |
| Everything (handing the tablet back, end of a contract) | Delete the app from the tablet | Android removes the app's storage and its secure storage. iPadOS removes the app's storage; it may keep the app's Keychain entries (the PIN's verifier and, with texting, the booth credential and any number not yet handed over), which only this app can read: a reinstalled booth replaces the verifier at setup, erases any number at its first start and replaces the credential when paired again. To remove them without reinstalling, erase the iPad (Settings > General > Transfer or Reset). Neither platform keeps booth data in its own backups (section 1) |

## 5. Backups (Settings > Backup)

- A backup is a single file holding the database and, if chosen, every
  photo. It contains guests' photos: store it like any other personal
  data (encrypted drive, limited access), and delete old backups.
- It never contains the PIN, the recovery code, the texting credential or
  any phone number. A restored booth asks for a new PIN and a new
  recovery code and must be paired again for texting; texts that were
  waiting are closed.
- The booth reads every backup back and checks it before offering it to
  the share sheet. The copy it keeps for sharing is removed the next time
  the app starts.
- Restore works only on a booth with nothing on it yet (first run), and
  only after the chosen file has been checked from end to end.

## 6. Access

- The Studio needs the operator PIN; wrong tries slow down and then lock
  out for a while; the recovery code resets the PIN.
- Booth Mode shows guests only the welcome, camera, review, finished and
  texting screens. The operator leaves with the hidden hold and the PIN.
- Lock the tablet to the app with the platform's kiosk feature
  (`docs/KIOSK_DEPLOYMENT.md`). The app cannot do that by itself;
  Settings > Kiosk lock shows whether the tablet reports a lock and how
  to turn one on.

## 7. If a tablet is lost

1. If texting was set up: revoke the booth at the delivery service at
   once (`docs/delivery/SETUP_AND_CREDENTIALS.md` section 9).
2. Photos on it are protected by the tablet's own passcode and
   encryption; the booth's PIN protects the Studio but is not
   encryption. Use a strong device passcode on every booth tablet.
3. Restore the latest backup to a replacement tablet.
