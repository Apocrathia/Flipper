# Flipper Zero SD card builder

Builds a Flipper Zero SD card from community content. One command:

```bash
./build-sd.sh
```

First run takes 10 to 15 minutes; the source clone alone is about 2.5 GB.
Later runs take a few minutes.

The script, in order:

1. Clones or updates the sources (no setup, no prompts)
2. Builds the content tree locally in `SD/`
3. Checks the build fits the card, with buffer
4. Deploys to the SD card
5. Removes macOS junk (`.DS_Store`, `._*`, and friends) from the build and the card
6. Prints a summary with file counts

If a step fails, the script stops and removes `SD/`. Nothing on the card
outside `playground/` folders and `apps/` is touched.

## Sources

- [UberGuidoZ/Flipper](https://github.com/UberGuidoZ/Flipper): BadUSB, Sub-GHz, NFC, infrared, RFID, music, dolphin graphics. Cloned shallow into `Playground/`.
- [Gutierre0x80/FlipperAmiiboCollection](https://github.[AWS_SECRET_KEY_STANDALONE_REDACTED]): 900+ cleaned, NTAG215-fixed amiibo `.nfc` files. Cloned into `AmiiboCollection/`.

## Where content lands

Repo folders map onto the Flipper's SD layout in `map_to_sd_category` in
`build-sd.sh`:

| Repo folder | Lands at | What it is |
| ----------- | -------- | ---------- |
| BadUSB | `/badusb/playground/` | keystroke payloads |
| Sub-GHz | `/subghz/playground/` | radio captures and tools |
| NFC | `/nfc/playground/` | NFC files and amiibo |
| Infrared | `/infrared/playground/` | IR remote databases |
| RFID | `/lfrfid/playground/` | low-frequency RFID utilities |
| Music_Player | `/music_player/playground/` | RTTTL tones |
| subplaylist | `/subplaylist/playground/` | Sub-GHz playlists |
| Dolphin_Level, Graphics | `/dolphin/playground/` | dolphin level hacks, custom animations |

Repo folders with no SD equivalent (`picopass`, `unirf`, `GPIO`,
`Wav_Player`, firmware variants, docs) are skipped. Categories with no
content are never deployed, so the card never gets empty `playground/`
folders.

### Apps

`Applications/Custom (UL, RM)/RogueMaster` deploys as the live app catalog to
`/apps/`: 750+ FAPs in the standard category folders, built for the current
Unleashed/RogueMaster API. The deploy replaces the catalog wholesale, so keep
personal FAPs in `/apps/playground/`, which the deploy preserves.

### Amiibo

Two collections land on the card:

- `/nfc/playground/Amiibo/Amiibo_Collection/`: the UberGuidoZ submodule
  (Gioman101), which includes the Tears of the Kingdom Zelda set
- `/nfc/playground/Amiibo/Amiibo_Collection_2026/`: the Gutierre0x80 2026
  set, cleaned and NTAG215-fixed

The 2023 amiibo zips in the repo are skipped. The Flipper cannot read zips.

## Requirements

- macOS, SD card mounted. Default path is `/Volumes/FLIPPER SD`; override
  with `SD_MOUNT=/path ./build-sd.sh`
- `git`, `rsync`, `bc`
- About 4 GB free disk for the clone and build. A 16 GB card is enough.

## Firmware

The script manages SD content only. To update Unleashed firmware:

1. Web installer: <https://web.unleashedflip.com>
2. qFlipper: Install, then Install from file, then the
   `flipper-z-f7-update-unlshd-XXe.tgz` from the
   [DarkFlippers releases](https://github.com/DarkFlippers/unleashed-firmware/releases)
3. SD card: copy the extracted `f7-update-*/` folder to `/update/` on the
   card, then run `update.fuf` on the device

A firmware update that bumps the API breaks existing FAPs. Update firmware
first, then run `./build-sd.sh`; the app catalog deploy brings FAPs built
for the new API.

## Troubleshooting

- Card not found: check `ls /Volumes/`, or set `SD_MOUNT`
- Out of space: the script refuses before touching the card; prune the
  mapping or get a bigger card
- Clone fails: check the network; delete `Playground/` to force a fresh clone
- Junk files on the card: macOS metadata is removed automatically at the end

## Legal

The payloads are for security research and education. Use them only on systems
you own or have permission to test. Some content may be restricted where you
live.
