#!/bin/bash

# ============================================================================
# Image Optimization Script
# ============================================================================
# 
# Purpose:
#   Optimizes image files to reduce size while maintaining quality.
#   - Resizes images larger than 3840px (width or height) to fit within 3840x3840
#   - Optimizes all images to 85% JPEG quality
#   - Strips metadata by default (for privacy and file size)
#
# Usage:
#   ./optimize-images.sh [options] [directory]
#
# Options:
#   --auto           Process all images without asking for confirmation
#   --interactive    Ask for confirmation for each image (default)
#   --keep-metadata  Preserve image metadata (default: strip metadata)
#   --quality N      Set JPEG quality (1-100, default: 85)
#   --max-size N     Set maximum image dimension (default: 3840)
#   --git-only       Only process uncommitted images in git repositories
#   --help           Show this help message
#
# Directory:
#   Path to directory containing images (default: current directory)
#
# Examples:
#   ./optimize-images.sh                             # Interactive mode, current directory
#   ./optimize-images.sh --auto                      # Auto mode, current directory
#   ./optimize-images.sh --git-only                  # Only uncommitted git images
#   ./optimize-images.sh --quality 90 images/       # Custom quality, specific directory
#   ./optimize-images.sh --max-size 2048 --auto     # Custom max size, auto mode
#
# Requirements:
#   - ImageMagick (install with: sudo apt-get install imagemagick)
#   - Git (optional, only needed for --git-only mode)
#
# ============================================================================

# Default settings
INTERACTIVE=true
STRIP_METADATA=true
QUALITY=85
MAX_SIZE=3840
GIT_ONLY=false
DIRECTORY="."

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            INTERACTIVE=false
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --keep-metadata)
            STRIP_METADATA=false
            shift
            ;;
        --quality)
            if [[ $2 =~ ^[0-9]+$ ]] && [ $2 -ge 1 ] && [ $2 -le 100 ]; then
                QUALITY=$2
                shift 2
            else
                echo "Error: Quality must be a number between 1 and 100"
                exit 1
            fi
            ;;
        --max-size)
            if [[ $2 =~ ^[0-9]+$ ]] && [ $2 -ge 100 ]; then
                MAX_SIZE=$2
                shift 2
            else
                echo "Error: Max size must be a number >= 100"
                exit 1
            fi
            ;;
        --git-only)
            GIT_ONLY=true
            shift
            ;;
        --help)
            head -n 40 "$0" | grep "^#" | sed 's/^# \?//'
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            DIRECTORY="$1"
            shift
            ;;
    esac
done

# Check requirements
if ! command -v mogrify &> /dev/null; then
    echo "Error: ImageMagick is not installed."
    echo ""
    echo "Please install ImageMagick:"
    echo "  Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "  macOS: brew install imagemagick"
    echo "  Windows WSL: sudo apt-get install imagemagick"
    exit 1
fi

if ! command -v identify &> /dev/null; then
    echo "Error: ImageMagick 'identify' command not found."
    echo "Please ensure ImageMagick is properly installed."
    exit 1
fi

if [ "$GIT_ONLY" = true ]; then
    if ! command -v git &> /dev/null; then
        echo "Error: Git is not installed (required for --git-only mode)."
        exit 1
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository (required for --git-only mode)."
        echo "Please run this script from within your project directory or remove --git-only."
        exit 1
    fi
fi

# Check if directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

# Change to target directory
cd "$DIRECTORY" || exit 1

# Find images based on mode
if [ "$GIT_ONLY" = true ]; then
    # Find new/modified images in git repository
    images=$(git status --porcelain | grep -E '^\?\?|^ M' | grep -E '\.(jpg|jpeg|png)$' | awk '{print $2}')
    
    # If no images found in git status (e.g., fresh repo), find all images
    if [ -z "$images" ]; then
        images=$(find . -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | grep -v ".git" | sed 's|^\./||')
    fi
else
    # Find all images in directory
    images=$(find . -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | sed 's|^\./||')
fi

if [ -z "$images" ]; then
    if [ "$GIT_ONLY" = true ]; then
        echo "No uncommitted images found."
    else
        echo "No images found in directory: $DIRECTORY"
    fi
    exit 0
fi

# Count images
image_count=$(echo "$images" | wc -l)

# Show what the script will do
echo "============================================"
echo "Image Optimization Script"
echo "============================================"
echo ""
echo "Directory: $(pwd)"
echo "Found $image_count image(s)"
echo ""
echo "This script will:"
echo "  • Resize images larger than ${MAX_SIZE}px to fit within ${MAX_SIZE}x${MAX_SIZE}"
echo "  • Optimize all images to ${QUALITY}% quality"
if [ "$STRIP_METADATA" = true ]; then
    echo "  • Strip metadata (EXIF, GPS, etc.)"
else
    echo "  • Keep metadata"
fi
echo ""

if [ "$INTERACTIVE" = true ]; then
    echo "Mode: Interactive (will ask for each image)"
else
    echo "Mode: Automatic (will process all images)"
fi
echo ""

# Process statistics
total_before=0
total_after=0
processed_count=0
skipped_count=0

# Process each image
for img in $images; do
    # Check if file exists (in case it was deleted after finding)
    if [ ! -f "$img" ]; then
        echo "Warning: $img no longer exists, skipping."
        ((skipped_count++))
        continue
    fi
    
    # Get file info
    size_before=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null || echo "0")
    size_kb=$(( size_before / 1024 ))
    
    # Get image dimensions
    dimensions=$(identify -format "%wx%h" "$img" 2>/dev/null || echo "unknown")
    width=$(echo "$dimensions" | cut -d'x' -f1)
    height=$(echo "$dimensions" | cut -d'x' -f2)
    
    # Determine if resize is needed
    needs_resize=false
    new_dimensions=""
    if [[ "$width" =~ ^[0-9]+$ ]] && [[ "$height" =~ ^[0-9]+$ ]]; then
        if [ "$width" -gt "$MAX_SIZE" ] || [ "$height" -gt "$MAX_SIZE" ]; then
            needs_resize=true
            # Calculate new dimensions maintaining aspect ratio
            if [ "$width" -gt "$height" ]; then
                new_width=$MAX_SIZE
                new_height=$(( (height * MAX_SIZE) / width ))
            else
                new_height=$MAX_SIZE
                new_width=$(( (width * MAX_SIZE) / height ))
            fi
            new_dimensions="${new_width}x${new_height}"
        fi
    fi
    
    # Show image info
    echo "----------------------------------------"
    echo "Image: $img"
    echo "Current: ${size_kb}KB, ${dimensions}"
    
    # Show what will be done
    echo "Actions:"
    if [ "$needs_resize" = true ]; then
        echo "  • Resize to approximately $new_dimensions"
    else
        echo "  • No resize needed (within ${MAX_SIZE}x${MAX_SIZE})"
    fi
    echo "  • Optimize to ${QUALITY}% quality"
    if [ "$STRIP_METADATA" = true ]; then
        echo "  • Strip metadata"
    else
        echo "  • Keep metadata"
    fi
    
    # Ask for confirmation if in interactive mode
    if [ "$INTERACTIVE" = true ]; then
        echo -n "Process this image? [Y/n/q] "
        read -r answer
        
        case "$answer" in
            [nN])
                echo "Skipped."
                ((skipped_count++))
                continue
                ;;
            [qQ])
                echo ""
                echo "Quitting. Processed $processed_count image(s), skipped $skipped_count."
                exit 0
                ;;
        esac
    fi
    
    # Build mogrify command arguments
    mogrify_args=()
    
    # Add resize if needed
    if [ "$needs_resize" = true ]; then
        mogrify_args+=("-resize" "${MAX_SIZE}x${MAX_SIZE}>")
    fi
    
    # Add quality setting
    mogrify_args+=("-quality" "$QUALITY")
    
    # Add strip metadata if requested
    if [ "$STRIP_METADATA" = true ]; then
        mogrify_args+=("-strip")
    fi
    
    # Execute the command with proper argument handling
    mogrify "${mogrify_args[@]}" "$img"
    
    if [ $? -eq 0 ]; then
        # Get new size
        size_after=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null || echo "0")
        
        # Calculate reduction
        if [ "$size_before" -gt 0 ]; then
            reduction=$(( ((size_before - size_after) * 100) / size_before ))
        else
            reduction=0
        fi
        
        # Update totals
        total_before=$((total_before + size_before))
        total_after=$((total_after + size_after))
        ((processed_count++))
        
        echo "✓ Optimized: $(( size_before / 1024 ))KB → $(( size_after / 1024 ))KB (-${reduction}%)"
    else
        echo "✗ Error processing image"
        ((skipped_count++))
    fi
done

# Show summary
echo ""
echo "============================================"
echo "Summary:"
echo "  • Processed: $processed_count image(s)"
echo "  • Skipped: $skipped_count image(s)"
if [ "$processed_count" -gt 0 ] && [ "$total_before" -gt 0 ]; then
    total_reduction=$(( ((total_before - total_after) * 100) / total_before ))
    echo "  • Total size: $(( total_before / 1024 ))KB → $(( total_after / 1024 ))KB (-${total_reduction}%)"
fi
echo ""

if [ "$GIT_ONLY" = true ]; then
    echo "Use 'git status' to see the changes."
    echo "Use 'git add' to stage the optimized images."
else
    echo "All images in directory processed."
fi