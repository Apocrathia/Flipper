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

# Function to clean existing playground content
clean_sd_card() {
    log_step "Cleaning existing playground content from SD card..."
    
    local cleaned_count=0
    
    # List of standard Flipper directories that might have playground content
    local flipper_dirs=(
        "apps" "badusb" "subghz" "nfc" "rfid" "infrared" 
        "music_player" "gpio" "lfrfid" "ibutton" "wav_player"
        "apps_data" "dolphin"
    )
    
    for dir in "${flipper_dirs[@]}"; do
        local playground_path="$SD_MOUNT/$dir/playground"
        if [ -d "$playground_path" ]; then
            log_info "Cleaning $dir/playground/"
            rm -rf "$playground_path"
            ((cleaned_count++))
        fi
    done
    
    log_success "Cleaned $cleaned_count directories from SD card"
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
    
    # Directory mappings (source:destination format)
    local mappings=(
        "Applications:apps/playground"
        "BadUSB:badusb/playground"
        "Sub-GHz:subghz/playground"
        "NFC:nfc/playground"
        "RFID:rfid/playground"
        "Infrared:infrared/playground"
        "Music_Player:music_player/playground"
        "GPIO:gpio/playground"
        "Graphics:apps_data/playground"
        "flipper_toolbox:apps_data/playground"
    )
    
    # Function to copy a directory if it exists
    copy_dir_if_exists() {
        local source="$1"
        local dest="$2"
        
        if [ -d "$PLAYGROUND_DIR/$source" ]; then
            log_info "Copying $source/ → $dest/ (excluding large files)"
            rsync -qa --mkpath \
                --exclude='.git' \
                --exclude='.DS_Store' \
                --exclude='*.wav' \
                --exclude='*.WAV' \
                --exclude='*.mp3' \
                --exclude='*.MP3' \
                --exclude='Wav_Player' \
                "$PLAYGROUND_DIR/$source/" "$WORKING_DIR/$dest/"
            
            # Calculate size
            local dir_size=$(du -sk "$WORKING_DIR/$dest" | cut -f1 2>/dev/null || echo "0")
            total_size=$((total_size + dir_size))
            
            ((copied_count++))
            log_success "✓ $source copied (audio files excluded)"
            return 0
        fi
        return 1
    }
    
    # Process all mappings
    local known_dirs=""
    for mapping in "${mappings[@]}"; do
        local source_dir="${mapping%:*}"
        local dest_dir="${mapping#*:}"
        known_dirs="$known_dirs $source_dir"
        copy_dir_if_exists "$source_dir" "$dest_dir"
    done
    
    # Copy any additional directories we might have missed
    log_info "Scanning for additional content..."
    for item in "$PLAYGROUND_DIR"/*; do
        if [ -d "$item" ] && [ ! -L "$item" ]; then
            local basename=$(basename "$item")
            # Skip if we already processed it or if it's a git/system directory
            if [[ ! " $known_dirs " =~ " ${basename} " ]] && [[ "$basename" != .* ]]; then
                log_warning "Found unmapped directory: $basename"
                copy_dir_if_exists "$basename" "apps_data/playground/$basename"
            fi
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
    
    # Deploy working directory to SD card
    log_info "Copying all organized content to SD card..."
    rsync -avh --info=progress2 --exclude='.DS_Store' "$WORKING_DIR/" "$SD_MOUNT/"
    
    log_success "All content deployed successfully to SD card"
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

# Function to clean OS metadata from working directory
clean_metadata() {
    log_step "Cleaning OS metadata files from working directory..."
    
    local cleaned_count=0
    
    # Remove .DS_Store files
    if find "$WORKING_DIR" -name ".DS_Store" -delete 2>/dev/null; then
        local ds_count=$(find "$WORKING_DIR" -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')
        if [ $ds_count -eq 0 ]; then
            log_info "Removed .DS_Store files"
            ((cleaned_count++))
        fi
    fi
    
    # Remove ._* resource fork files
    local rf_files=$(find "$WORKING_DIR" -name "._*" 2>/dev/null | wc -l | tr -d ' ')
    if [ $rf_files -gt 0 ]; then
        find "$WORKING_DIR" -name "._*" -delete 2>/dev/null
        log_info "Removed $rf_files resource fork files"
        ((cleaned_count++))
    fi
    
    # Remove other OS metadata directories/files
    local metadata_items=(
        ".Spotlight-V100"
        ".fseventsd" 
        ".Trashes"
        ".TemporaryItems"
        "Thumbs.db"
        ".DocumentRevisions-V100"
    )
    
    for item in "${metadata_items[@]}"; do
        if find "$WORKING_DIR" -name "$item" -exec rm -rf {} + 2>/dev/null; then
            log_info "Removed $item metadata"
            ((cleaned_count++))
        fi
    done
    
    # Remove empty directories that might have been left behind
    find "$WORKING_DIR" -type d -empty -delete 2>/dev/null
    
    if [ $cleaned_count -gt 0 ]; then
        log_success "Cleaned $cleaned_count types of metadata files"
    else
        log_success "No metadata files found to clean"
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
    clean_sd_card
    clean_metadata # Clean metadata before deployment
    deploy_to_sd_card
    create_summary
    cleanup
    
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
