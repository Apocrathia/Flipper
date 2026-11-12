# Pitfalls

Every item below has bitten at least once. Read this before editing
`build-sd.sh` or deploying.

- **macOS ships openrsync, not rsync 3.** `/usr/bin/rsync` is openrsync
  (rsync 2.6.9 compatible). `--info=stats` and friends do not exist; use
  `--stats`. Any new rsync flag must work on openrsync.
- **Never edit `build-sd.sh` while it runs.** The deploy takes minutes and
  writes thousands of files to the card; bash reads scripts incrementally,
  so mid-run edits corrupt execution. Queue script changes until the run
  finishes.
- **The serial port is exclusive.** qFlipper, a web flasher tab, or another
  serial session locks the device. Close the holder before scripting
  against it.
- **The Flipper CLI echoes but does not answer bare LF.** Send `
`, or
  commands look hung.
- **Old FAPs vanish after an API bump.** The loader rejects mismatched
  manifests, so the Apps menu and `loader list` show nothing from SD until
  the catalog is refreshed. That includes `mass_storage.fap`: the
  in-device mass-storage flow needs a catalog built for the installed API.
  The card-in-reader flow has no such dependency.
- **Repo folder names are Title_Case and do not match SD names.**
  `Sub-GHz` is not `subghz`; `Applications` is not `apps`. Name-based
  matching silently skips these. Use the mapping table; extend it
  deliberately.
- **Deploy uses rsync `--delete` per category.** Anything personal in a
  `playground/` folder or the `apps/` catalog is replaced on the next run.
  Personal FAPs go in `/apps/playground/` (preserved by the catalog
  deploy); personal captures go in the SD root category folders, never
  `playground/`.
- **The card does not always automount.** If the script cannot find it,
  `diskutil list external`, then `diskutil mount <diskNs1>`.
- **AppleDouble junk accumulates on the card.** `._*` files from macOS
  readers number in the tens of thousands on a long-lived card. The script
  removes them at deploy time; do not disable that.
