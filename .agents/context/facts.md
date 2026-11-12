# Facts

The world this script operates in, verified 2026-11-12. Update the file when
the firmware ecosystem or the sources change. See
[`pitfalls.md`](pitfalls.md) for the traps.

## Flipper Zero specifics

- The device CLI speaks over USB CDC-ACM at 230400 baud and needs CRLF
  line endings (`
`), not bare LF. Commands echo but never answer with
  bare LF.
- qFlipper holds the device exclusively while it runs. Anything else that
  wants the serial port (a script, another installer, a browser tab with a
  web flasher) must wait; a `Resource busy` port means something holds it.
- The SD card is FAT32 and mounts under its volume label (default
  `/Volumes/FLIPPER SD`, matching the script's `SD_MOUNT`). If it does not
  automount: `diskutil list external`, then `diskutil mount <diskNs1>`.

## Firmware

- The target firmware is Unleashed (`DarkFlippers/unleashed-firmware`,
  release-cfw branch). It releases about monthly. Current line as of
  2026-11-12: `unlshd-095e` (2026-11-11), API 88.26. The `e` suffix means
  extended resources, not apps.
- Momentum is stalled (last release `mntm-012`, 2025-12-31). RogueMaster is
  Unleashed-based, same API, active. Unleashed has no takedown or DMCA
  history, despite recurring rumors.
- Firmware updates do not touch SD content, but an API bump hides every FAP
  built for the old API. Update firmware first, then run `./build-sd.sh` to
  refresh the app catalog.
- Update paths: web installer (`https://web.unleashedflip.com`), qFlipper
  Install from file with the `flipper-z-f7-update-unlshd-XXe.tgz` from the
  GitHub releases, or copy the extracted `f7-update-*/` folder to `/update/`
  on the card and run `update.fuf` on device.
- A firmware update package (`f7-update-*`) contains firmware, radio, and
  resources. No apps. Applied packages linger in `/update/` on the card and
  can be deleted.

## Content sources

- `UberGuidoZ/Flipper` (default branch `main`, about 2.2 GB plus 28
  submodules): Title_Case top-level folders. Content lands on the card via
  the mapping table in `build-sd.sh` (`map_to_sd_category`).
- `Gutierre0x80/FlipperAmiiboCollection` (`main`): 930+ cleaned,
  NTAG215-fixed amiibo NFC files, the freshest curated set as of
  2026-11-12. It has no Tears of the Kingdom files; the older
  Gioman101 submodule checkout does, so both stay on the card.
- Amiibo zips in `NFC/Amiibo/Amiibo_Files/` are frozen 2023 vintage and
  excluded from deploy. The Flipper cannot read zips.

## Known dead ends (do not re-research)

- Zelda 40th anniversary amiibo (Ocarina-of-Time-series Young Link and
  Young Zelda) launch in 2027 per Nintendo. No dumps can exist before the
  figures ship. The only 2026 Zelda amiibo is Mineru's Construct
  (2026-09-17), absent from every collection checked as of 2026-11-12.
  Check the collections before assuming newer amiibo exist.
