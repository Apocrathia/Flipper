#!/bin/bash

# Flipper Zero SD Card Builder
# Comprehensive script to clean, organize, and deploy all content to SD card

set -e  # Exit on any error

# Configuration
SD_MOUNT="/Volumes/FLIPPER SD"
WORKING_DIR="SD"
PLAYGROUND_DIR="Playground"
PLAYGROUND_REPO="https://github.com/UberGuidoZ/Flipper"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🔄 $1${NC}"; }

# List of OS metadata file patterns (constant)
OS_METADATA_PATTERNS=(
    ".DS_Store"
    "._*"
    ".Spotlight-V100"
    ".fseventsd"
    ".Trashes"
    ".TemporaryItems"
    "Thumbs.db"
    ".DocumentRevisions-V100"
)

# Additional ignore patterns (constant)
IGNORE_PATTERNS=(
    ".git"
    "Wav_Player"
    "*.wav"
    "*.WAV"
    "*.mp3"
    "*.MP3"
)

# Variables to track metadata cleanup stats
META_FOUND_WORK=0
META_CLEANED_WORK=0
META_FOUND_SD=0
META_CLEANED_SD=0

# Helper to build rsync --exclude args from pattern arrays
build_rsync_excludes() {
    local patterns=("${@}")
    local args=()
    for pattern in "${patterns[@]}"; do
        args+=(--exclude="$pattern")
    done
    echo "${args[@]}"
}

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if SD card is mounted
    if [ ! -d "$SD_MOUNT" ]; then
        log_error "Flipper SD card not found at $SD_MOUNT"
        log_info "Please ensure your Flipper SD card is connected and mounted"
        exit 1
    fi
    
    # Check if SD card is writable
    if [ ! -w "$SD_MOUNT" ]; then
        log_error "SD card is not writable. Check permissions."
        exit 1
    fi
    
    # Check if source directories exist
    if [ ! -d "$PLAYGROUND_DIR" ]; then
        log_error "Playground directory not found: $PLAYGROUND_DIR"
        exit 1
    fi
    
    # Check for git (needed to update Playground repo)
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Function to update Playground repository
update_playground_repo() {
    log_step "Updating Playground repository..."
    
    cd "$PLAYGROUND_DIR"
    
    # Check if this is the correct repository
    current_remote=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [ "$current_remote" != "$PLAYGROUND_REPO" ]; then
        log_warning "Playground repository URL doesn't match expected UberGuidoZ repo"
        log_info "Current: $current_remote"
        log_info "Expected: $PLAYGROUND_REPO"
        log_info "You may need to run: git remote set-url origin $PLAYGROUND_REPO"
    fi
    
    # Update the repository
    log_info "Pulling latest changes..."
    git pull origin main
    
    # Update submodules
    log_info "Updating submodules..."
    git submodule update --init --recursive
    
    cd ..
    log_success "Playground repository updated successfully"
}

# Function to create working directory structure
setup_working_directory() {
    log_step "Setting up local working directory..."
    
    # Clean and create working directory
    if [ -d "$WORKING_DIR" ]; then
        rm -rf "$WORKING_DIR"
    fi
    mkdir -p "$WORKING_DIR"
    
    # Create standard Flipper directory structure
    local standard_dirs=(
        "apps/playground"
        "badusb/playground" 
        "subghz/playground"
        "nfc/playground"
        "rfid/playground"
        "infrared/playground"
        "music_player/playground"
        "gpio/playground"
        "lfrfid/playground"
        "ibutton/playground"
        "apps_data/playground"
        "dolphin/playground"
    )
    
    for dir in "${standard_dirs[@]}"; do
        mkdir -p "$WORKING_DIR/$dir"
    done
    
    log_success "Local working directory structure created"
}

# Function to copy Playground content with comprehensive mapping
copy_playground_content() {
    log_step "Copying Playground content to local working directory..."
    
    local copied_count=0
    local total_size=0

    # Build rsync exclude args (combine ignore + metadata)
    local EXCLUDES=("${IGNORE_PATTERNS[@]}" "${OS_METADATA_PATTERNS[@]}")
    local RSYNC_EXCLUDES=( $(build_rsync_excludes "${EXCLUDES[@]}") )

    # Dynamically map Playground folders to working dir if SD root folder exists
    for item in "$PLAYGROUND_DIR"/*; do
        local basename=$(basename "$item")
        # Skip if not a directory, is a symlink, or is Wav_Player
        if [ ! -d "$item" ] || [ -L "$item" ] || [ "$basename" = "Wav_Player" ]; then
            continue
        fi
        # Only map if SD root has this folder
        if [ -d "$SD_MOUNT/$basename" ]; then
            local dest="$WORKING_DIR/$basename/playground"
            mkdir -p "$dest"
            log_info "Copying $basename/ → $basename/playground"
            rsync -qa --mkpath \
                ${RSYNC_EXCLUDES[@]} \
                "$PLAYGROUND_DIR/$basename/" "$dest/"
            # Calculate size
            local dir_size=$(du -sk "$dest" | cut -f1 2>/dev/null || echo "0")
            total_size=$((total_size + dir_size))
            ((copied_count++))
            log_success "✓ $basename copied"
        fi
    done
    log_success "Copied $copied_count content directories ($(echo "scale=1; $total_size/1024" | bc)MB total)"
}

# Function to estimate content size before cleaning SD card
estimate_content_size() {
    log_step "Checking if built content will fit on SD card..."
    
    # Calculate size of the built working directory (this is what we'll actually deploy)
    local working_size_kb=$(du -sk "$WORKING_DIR" | cut -f1)
    local working_size_mb=$((working_size_kb / 1024))
    
    # Get total SD card capacity (not just free space)
    local total_kb=$(df -k "$SD_MOUNT" | awk 'NR==2{print $2}')
    local total_mb=$((total_kb / 1024))
    
    # Add 20% buffer for safety (more conservative estimate)
    local needed_kb=$((working_size_kb * 120 / 100))
    local needed_mb=$((needed_kb / 1024))
    
    log_info "Built content size: ${working_size_mb}MB"
    log_info "Total SD card capacity: ${total_mb}MB"
    log_info "Required (with 20% buffer): ${needed_mb}MB"
    
    if [ $needed_kb -gt $total_kb ]; then
        log_error "SD card is too small for this content!"
        log_error "Need: ${needed_mb}MB, SD card total capacity: ${total_mb}MB"
        log_error "Aborting before cleaning SD card to preserve existing content"
        log_info "You need a larger SD card (recommend 32GB+)"
        return 1
    fi
    
    local remaining_mb=$(((total_kb - needed_kb) / 1024))
    log_success "SD card is large enough! Estimated ${remaining_mb}MB will remain for other content"
    log_info "Proceeding with SD card cleanup and deployment..."
    return 0
}

# Function to check if content will fit on SD card after cleanup
check_sd_space() {
    log_step "Final space verification before deployment..."
    
    # Calculate size of working directory
    local working_size_kb=$(du -sk "$WORKING_DIR" | cut -f1)
    local working_size_mb=$((working_size_kb / 1024))
    
    # Get available space on SD card (in KB) - should be more now after cleanup
    local available_kb=$(df -k "$SD_MOUNT" | awk 'NR==2{print $4}')
    local available_mb=$((available_kb / 1024))
    
    # Add 10% buffer for safety
    local needed_kb=$((working_size_kb * 110 / 100))
    local needed_mb=$((needed_kb / 1024))
    
    log_info "Content size: ${working_size_mb}MB"
    log_info "Available space (after cleanup): ${available_mb}MB"
    log_info "Required (with 10% buffer): ${needed_mb}MB"
    
    if [ $needed_kb -gt $available_kb ]; then
        log_error "Built content won't fit in available space!"
        log_error "Need: ${needed_mb}MB, Available: ${available_mb}MB"
        log_info "This could mean other content on SD card is using more space than expected"
        return 1
    fi
    
    local remaining_mb=$(((available_kb - needed_kb) / 1024))
    log_success "Content will fit! ${remaining_mb}MB will remain free"
    return 0
}

# Function to deploy everything to SD card
deploy_to_sd_card() {
    log_step "Deploying all content to SD card..."
    
    # Check if content will fit before deploying
    if ! check_sd_space; then
        log_error "Aborting deployment due to insufficient space"
        return 1
    fi

    # Build rsync exclude args (combine ignore + metadata)
    local EXCLUDES=("${IGNORE_PATTERNS[@]}" "${OS_METADATA_PATTERNS[@]}")
    local RSYNC_EXCLUDES=( $(build_rsync_excludes "${EXCLUDES[@]}") )

    # For each folder in SD root, if working dir has playground content, sync it
    for dir in "$SD_MOUNT"/*; do
        local basename=$(basename "$dir")
        local src="$WORKING_DIR/$basename/playground/"
        local dst="$SD_MOUNT/$basename/playground/"
        if [ -d "$src" ]; then
            log_info "Syncing $basename/playground/ to SD card..."
            # rsync -avh --delete --info=progress2 ${RSYNC_EXCLUDES[@]} "$src" "$dst" # Uncomment for verbose output
            rsync -avh --inplace --delete --info=stats ${RSYNC_EXCLUDES[@]} "$src" "$dst"
        fi
    done

    log_success "All playground content synchronized to SD card efficiently"
}

# Function to create deployment summary
create_summary() {
    log_step "Creating deployment summary..."
    
    # Count files by type
    local badusb_count=$(find "$SD_MOUNT/badusb" -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
    local subghz_count=$(find "$SD_MOUNT/subghz" -name "*.sub" 2>/dev/null | wc -l | tr -d ' ')
    local nfc_count=$(find "$SD_MOUNT/nfc" -name "*.nfc" 2>/dev/null | wc -l | tr -d ' ')
    local ir_count=$(find "$SD_MOUNT/infrared" -name "*.ir" 2>/dev/null | wc -l | tr -d ' ')
    local app_count=$(find "$SD_MOUNT/apps" -name "*.fap" 2>/dev/null | wc -l | tr -d ' ')
    local music_count=$(find "$SD_MOUNT/music_player" -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
    
    echo ""
    echo -e "${CYAN}📊 Deployment Summary${NC}"
    echo "=========================="
    echo -e "${GREEN}✅ BadUSB payloads:${NC} $badusb_count files"
    echo -e "${GREEN}✅ Sub-GHz captures:${NC} $subghz_count files" 
    echo -e "${GREEN}✅ NFC tags:${NC} $nfc_count files"
    echo -e "${GREEN}✅ Infrared remotes:${NC} $ir_count files"
    echo -e "${GREEN}✅ Applications:${NC} $app_count FAP files"
    echo -e "${GREEN}✅ Music files:${NC} $music_count files"
    echo ""

    # Metadata cleanup stats
    echo -e "${CYAN}🧹 Metadata Cleanup:${NC}"
    echo "   • Working directory:  Found $META_FOUND_WORK, Cleaned $META_CLEANED_WORK"
    echo "   • SD card:           Found $META_FOUND_SD, Cleaned $META_CLEANED_SD"
    echo ""

    # Calculate total used space
    local total_used=$(df -h "$SD_MOUNT" | awk 'NR==2{print $3}')
    local total_avail=$(df -h "$SD_MOUNT" | awk 'NR==2{print $4}')
    
    echo -e "${BLUE}💾 SD Card Usage:${NC} $total_used used, $total_avail available"
    echo -e "${CYAN}📁 Content Organization:${NC}"
    echo "   • Playground content → organized in /[category]/playground/ directories"
    echo ""
}

# Function to cleanup working directory
cleanup() {
    log_step "Cleaning up local working directory..."
    if [ -d "$WORKING_DIR" ]; then
        rm -rf "$WORKING_DIR"
        log_success "Local working directory cleaned"
    fi
}

# Function to clean OS metadata from a target directory
clean_metadata() {
    local target_dir="$1"
    log_step "Cleaning OS metadata files from $target_dir..."
    local cleaned_count=0
    for pattern in "${OS_METADATA_PATTERNS[@]}"; do
        local matches=$(find "$target_dir" -name "$pattern" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$matches" -gt 0 ]; then
            find "$target_dir" -name "$pattern" -exec rm -rf {} + 2>/dev/null
            log_info "Removed $matches $pattern files"
            ((cleaned_count++))
        fi
    done
    # Remove empty directories that might have been left behind
    find "$target_dir" -type d -empty -delete 2>/dev/null
    if [ $cleaned_count -gt 0 ]; then
        log_success "Cleaned $cleaned_count types of metadata files"
    else
        log_success "No metadata files found to clean"
    fi
}

# Function to scan for OS metadata files in a target directory
scan_metadata() {
    local target_dir="$1"
    log_step "Scanning $target_dir for OS metadata files..."
    local find_expr=""
    for pattern in "${OS_METADATA_PATTERNS[@]}"; do
        find_expr+=" -o -name '$pattern'"
    done
    find_expr=${find_expr# -o } # Remove leading -o
    SCAN_METADATA_FILES=$(eval find "$target_dir" \( $find_expr \) 2>/dev/null)
    SCAN_METADATA_COUNT=$(echo "$SCAN_METADATA_FILES" | grep -c "/")
    SCAN_METADATA_COUNT=${SCAN_METADATA_COUNT:-0}
    if [ "$SCAN_METADATA_COUNT" -gt 0 ]; then
        log_warning "Found $SCAN_METADATA_COUNT OS metadata files in $target_dir."
        echo "$SCAN_METADATA_FILES"
        return 0
    else
        log_success "No OS metadata files found in $target_dir."
        return 1
    fi
}

# Main execution
main() {
    echo -e "${PURPLE}"
    echo "🐬 Flipper Zero SD Card Builder v2.0"
    echo "====================================="
    echo -e "${CYAN}📦 Source: UberGuidoZ/Flipper (via Playground)${NC}"
    echo ""

    # Execute all steps
    check_prerequisites
    update_playground_repo
    setup_working_directory
    copy_playground_content
    estimate_content_size || exit 1  # Check size of built content before cleaning SD

    # Scan for OS metadata files in working directory and prompt for cleanup if found
    if scan_metadata "$WORKING_DIR"; then
        META_FOUND_WORK=$SCAN_METADATA_COUNT
        echo
        echo "${YELLOW}⚠️  Notice: Found $SCAN_METADATA_COUNT OS metadata files in working directory before deployment.${NC}"
        echo "These are not needed and can be safely removed."
        echo "Do you want to clean them up now? (y/N) "
        read -r CLEAN_WORK_META
        if [[ "$CLEAN_WORK_META" =~ ^[Yy]$ ]]; then
            echo "$SCAN_METADATA_FILES" | while read -r file; do
                if [ -e "$file" ]; then
                    rm -rf "$file"
                    log_info "Removed $file"
                fi
            done
            META_CLEANED_WORK=$SCAN_METADATA_COUNT
            log_success "Cleaned $SCAN_METADATA_COUNT OS metadata files in working directory."
        else
            log_info "Skipped cleaning OS metadata files in working directory."
        fi
    fi

    deploy_to_sd_card
    cleanup

    # Scan for OS metadata files on SD card and prompt for cleanup if found
    if scan_metadata "$SD_MOUNT"; then
        META_FOUND_SD=$SCAN_METADATA_COUNT
        echo
        echo "${YELLOW}⚠️  Notice: Found $SCAN_METADATA_COUNT OS metadata files on SD card.${NC}"
        echo "These are not needed and can be safely removed."
        echo "Do you want to clean them up now? (y/N) "
        read -r CLEAN_SD_META
        if [[ "$CLEAN_SD_META" =~ ^[Yy]$ ]]; then
            echo "$SCAN_METADATA_FILES" | while read -r file; do
                if [ -e "$file" ]; then
                    rm -rf "$file"
                    log_info "Removed $file"
                fi
            done
            META_CLEANED_SD=$SCAN_METADATA_COUNT
            log_success "Cleaned $SCAN_METADATA_COUNT OS metadata files on SD card."
        else
            log_info "Skipped cleaning OS metadata files on SD card."
        fi
    fi

    create_summary

    echo ""
    echo -e "${GREEN}🎉 SD Card build complete!${NC}"
    echo -e "${CYAN}💡 Your Flipper Zero is ready with the latest UberGuidoZ content${NC}"
    echo -e "${YELLOW}📝 Note: This script automatically updates repositories before building${NC}"
    echo ""
}

# Error handling
trap 'log_error "Build failed. Cleaning up..."; cleanup; exit 1' ERR

# Run main function
main "$@"
