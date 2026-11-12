# AGENTS.md

# Flipper

One script (`build-sd.sh`) builds a Flipper Zero SD card from community
content and updates the firmware ecosystem around it. This is a light
install of the context engine: two context files, no rules, no skills, no
personas. A one-script repo needs none of those.

## The one command

```bash
./build-sd.sh
```

First run 10 to 15 minutes (the UberGuidoZ clone is about 2.2 GB), later
runs a few minutes. The SD card must be mounted on this Mac when the script
runs; default path `/Volumes/FLIPPER SD`, override with `SD_MOUNT=`.

## Always in force

- Never edit `build-sd.sh` while it is running. Bash reads scripts
  incrementally; mid-run edits corrupt execution.
- The script writes only to `playground/` folders and the `apps/` catalog.
  Anything else on the card belongs to the owner and is not ours to touch.
- `Playground/`, `AmiiboCollection/`, `SD/`, and `.scratch/` are
  re-creatable. `build-sd.sh` and this context tree are not.
- Throwaway output goes in `.scratch/` (gitignored). Back up any file before
  a risky or bulk edit (`.scratch/backups/`).
- Answer first, supporting detail after. The operator cannot read at agent
  speed.

## Routing

Read the module your task touches, not everything:

| If the task is about...               | Read                                                         |
| ------------------------------------- | ------------------------------------------------------------ |
| the device, firmware, or update flow  | [`.agents/context/facts.md`](.agents/context/facts.md)       |
| editing the script or deploying       | [`.agents/context/pitfalls.md`](.agents/context/pitfalls.md) |
| content sources, amiibo, apps catalog | [`.agents/context/facts.md`](.agents/context/facts.md)       |

## The context is living

When a change makes one of these files wrong (new firmware line, new source
repo, card replaced), fix the file in the same change. Drift you cannot fix
gets a `<!-- drift: ... -->` note for the next agent.
