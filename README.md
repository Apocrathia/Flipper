# Flipper Zero SD Card Management System

This repository provides a streamlined system to build and maintain a comprehensive Flipper Zero SD card with the latest community content from UberGuidoZ's curated collection.

## 📁 Repository Overview

This system automatically organizes content from UberGuidoZ's Flipper repository into a properly structured SD card:

- **Content Source**: [UberGuidoZ's Flipper Repository](https://github.com/UberGuidoZ/Flipper) (via Playground directory)
- **Automation**: Single script handles everything automatically

## 🛠️ Script Overview

### `build-sd.sh` - Complete Solution ⭐

The main script that handles everything:

- **Updates** Playground repository automatically (latest UberGuidoZ content)
- **Builds** content locally on fast NVMe drive (SD card friendly)
- **Organizes** content into proper Flipper directory structure
- **Checks** if content fits on SD card before deployment (with buffer)
- **Cleans** OS metadata files (like .DS_Store) from both working directory and SD card, with interactive prompts
- **Deploys** everything to your SD card efficiently (only affects playground directories)
- **Reports** a comprehensive deployment summary
- **Handles errors** robustly and cleans up after failures

## 📦 Content Categories

Your SD card will be organized with:

| Category         | Description                      | Location                    |
| ---------------- | -------------------------------- | --------------------------- |
| **BadUSB**       | Keystroke injection payloads     | `/badusb/playground/`       |
| **Sub-GHz**      | Radio frequency captures & tools | `/subghz/playground/`       |
| **NFC**          | Near-field communication files   | `/nfc/playground/`          |
| **Infrared**     | IR remote control databases      | `/infrared/playground/`     |
| **RFID**         | RFID tag files and utilities     | `/rfid/playground/`         |
| **Music Player** | RTTTL tones and audio files      | `/music_player/playground/` |
| **Applications** | External FAP applications        | `/apps/playground/`         |
| **GPIO**         | Hardware interfacing tools       | `/gpio/playground/`         |
| **Graphics**     | Flipper animations and artwork   | `/apps_data/playground/`    |

## 🚀 Quick Start

### Prerequisites

- macOS with Flipper Zero SD card mounted at `/Volumes/FLIPPER SD/`
- Git installed for repository updates
- Sufficient SD card space (recommended: 32GB+)

### Simple Usage

**One command does everything:**

```bash
./build-sd.sh
```

This single command will:

1. ✅ Update repository to latest content
2. ✅ Build everything locally (protects SD card)
3. ✅ Check if content fits on SD card (with buffer)
4. ✅ Prompt to clean OS metadata files (optional)
5. ✅ Deploy to SD card
6. ✅ Show comprehensive summary

### Advanced Usage

- **Custom mount point**: Edit the `SD_MOUNT` variable in `build-sd.sh` to change `/Volumes/FLIPPER SD/` path
- **Content filtering**: Modify the script logic to exclude categories if needed

## ⚠️ Important Considerations

### Legal & Ethical Use

- **Educational Purpose**: This content is for security research and education
- **Authorization Required**: Only use on systems you own or have explicit permission to test
- **Know Your Laws**: Some tools may be restricted in your jurisdiction

### Technical Notes

- Script assumes macOS environment with standard SD card mounting
- **SD card protection**: Builds locally first, then deploys (reduces flash wear)
- **Space checking**: Automatically verifies content will fit before deployment, with a safety buffer
- Script will overwrite content in "playground" directories only
- External applications require compatible Flipper firmware
- **Metadata cleanup**: Script scans for and can remove OS metadata files (like .DS_Store) from both the working directory and SD card, with user confirmation
- **Error handling**: If any step fails, the script cleans up and exits safely

### Storage Requirements

- Repository download: ~2-4GB
- Full SD card deployment: ~4-8GB (varies with content updates)
- Recommended SD card: 32GB Class 10 or better

## 📂 Directory Structure

```
Flipper/
├── build-sd.sh          # Main deployment script (everything you need!)
├── Playground/          # UberGuidoZ repository content (auto-managed)
├── SD/                  # Working directory (created/cleaned automatically)
└── README.md            # This file
```

## 🤝 Content Source

### UberGuidoZ's Flipper Repository

- **Repository**: https://github.com/UberGuidoZ/Flipper
- **Content**: Comprehensive, curated collection of Flipper Zero files
- **Quality**: High - actively maintained and community-vetted
- **Updates**: Automatic via `build-sd.sh`
- **Organization**: Automatically sorted into proper Flipper directory structure

## 🔄 Maintenance

### Regular Updates

**Simple workflow:**

```bash
./build-sd.sh    # Updates repository + deploys latest content
```

Run this monthly or whenever you want the latest community content.

### Troubleshooting

- **Mount Issues**: Verify SD card path with `ls /Volumes/`
- **Permission Errors**: Ensure SD card is writable
- **Space Issues**: Script will warn you - consider larger SD card or content filtering
- **Git Errors**: Check internet connection and repository access
- **Metadata Files**: Script will prompt to clean up OS metadata files if found
- **Size Problems**: Check script output for space requirements vs. available space

## 🎯 What Makes This Better

### Efficiency

- **Single command**: No multi-step workflows
- **Local building**: Protects SD card from excessive writes
- **Smart deployment**: Only copies when content fits (with buffer)
- **Automatic updates**: Always gets latest content
- **Metadata cleanup**: Optionally removes unnecessary files for a clean SD card

### Safety

- **Space checking**: Prevents SD card overflow
- **Content isolation**: Only affects playground directories
- **Error handling**: Comprehensive error checking and reporting
- **Backup friendly**: Preserves existing non-playground content

### Maintainability

- **Clean code**: Well-structured, documented script
- **Easy mapping**: Dynamic directory mapping for content organization
- **Extensible**: Easy to add new content categories
- **Cross-platform ready**: Designed for easy adaptation to other OS

## 📝 Contributing

- Report issues with the script or content organization
- Suggest improvements to deployment process
- Share feedback on content categorization

## 📄 License

Content is aggregated from UberGuidoZ's repository with respect to original licensing terms. Use responsibly and ethically.

---

**⚡ Happy Flipping!**

_One script to rule them all - `./build-sd.sh`_
