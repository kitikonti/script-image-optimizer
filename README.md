# Image Optimization Script

A powerful bash script for optimizing images to reduce file size while maintaining quality. Perfect for web development projects, git repositories, and general image processing workflows.

## Features

- **Smart Resizing**: Automatically resizes images larger than specified dimensions while maintaining aspect ratio
- **Quality Optimization**: Compresses images to specified JPEG quality (default: 85%)
- **Metadata Handling**: Strips EXIF, GPS, and other metadata by default (configurable)
- **Git Integration**: Can process only uncommitted images in git repositories
- **Interactive Mode**: Ask for confirmation before processing each image
- **Batch Processing**: Process all images automatically with `--auto` flag
- **Flexible Configuration**: Customizable quality, max size, and directory options
- **Progress Tracking**: Shows file size reduction and processing statistics

## Installation

### Prerequisites

**ImageMagick** is required for image processing:

```bash
# Ubuntu/Debian
sudo apt-get install imagemagick

# macOS
brew install imagemagick

# Windows WSL
sudo apt-get install imagemagick
```

### Download Script

```bash
# Clone the repository
git clone git@github.com:kitikonti/script-image-optimizer.git
cd script-image-optimizer

# Make script executable
chmod +x optimize-images.sh
```

## Usage

### Basic Usage

**IMPORTANT: For git-focused mode (default), stage files first with `git add .`**

```bash
# Stage files and run in interactive mode (default)
git add . && ./optimize-images.sh

# Stage files and run in automatic mode (no prompts)
git add . && ./optimize-images.sh --auto

# Process all images regardless of git status
./optimize-images.sh --all-images

# Process specific directory with all images
./optimize-images.sh --all-images /path/to/images/
```

### Advanced Options

```bash
# Custom quality setting (1-100)
./optimize-images.sh --quality 90

# Custom maximum image size
./optimize-images.sh --max-size 2048

# Keep metadata instead of stripping
./optimize-images.sh --keep-metadata

# Combine options
./optimize-images.sh --auto --quality 90 --max-size 2048 --keep-metadata
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--auto` | Process all images without asking for confirmation | Interactive mode |
| `--interactive` | Ask for confirmation for each image | Default |
| `--keep-metadata` | Preserve image metadata (EXIF, GPS, etc.) | Strip metadata |
| `--quality N` | Set JPEG quality (1-100) | 85 |
| `--max-size N` | Set maximum image dimension in pixels | 3840 |
| `--git-only` | Only process uncommitted images in git repositories | Process all images |
| `--help` | Show help message | - |

## Examples

### Web Development Workflow

```bash
# Recommended workflow: Stage files first, then optimize
git add .
./optimize-images.sh --auto
git commit -m "Add optimized images"

# Alternative: Process all images regardless of git status
./optimize-images.sh --all-images --auto --quality 85 --max-size 3840
```

### Photography Workflow

```bash
# Process photos while keeping metadata
./optimize-images.sh --keep-metadata --quality 95 --max-size 4096

# Interactive processing for selective optimization
./optimize-images.sh --interactive --quality 90
```

### Batch Processing

```bash
# Process multiple directories
for dir in images/ photos/ assets/; do
    ./optimize-images.sh --auto "$dir"
done
```

## How the Script Works

### Git-Focused Mode (Default)
1. **Requires Staging**: Run `git add .` first to stage files
2. **Finds Staged Images**: Locates staged `.jpg`, `.jpeg`, and `.png` files
3. **Respects .gitignore**: Only processes files that git would track
4. **Safe for Repos**: Prevents processing build artifacts or ignored files

### All-Images Mode (--all-images flag)
1. **Finds All Images**: Locates all `.jpg`, `.jpeg`, and `.png` files in directory
2. **Ignores Git Status**: Processes everything regardless of git tracking
3. **Directory Processing**: Useful for batch processing image folders

### Processing Steps
1. **Analyzes**: Checks file size, dimensions, and determines optimization needs
2. **Resizes**: Reduces images larger than max size while maintaining aspect ratio
3. **Optimizes**: Compresses images to specified quality level
4. **Strips Metadata**: Removes EXIF, GPS, and other metadata (unless `--keep-metadata` is used)
5. **Reports**: Shows file size reduction and processing statistics

## Output Example

```
============================================
Image Optimization Script
============================================

Directory: /home/user/project/images
Found 3 image(s)

This script will:
  • Resize images larger than 3840px to fit within 3840x3840
  • Optimize all images to 85% quality
  • Strip metadata (EXIF, GPS, etc.)

Mode: Automatic (will process all images)

----------------------------------------
Image: photo1.jpg
Current: 5234KB, 5472x3648
Actions:
  • Resize to approximately 3840x2560
  • Optimize to 85% quality
  • Strip metadata
✓ Optimized: 5234KB → 1456KB (-72%)

----------------------------------------
Image: photo2.jpg
Current: 2341KB, 3000x2000
Actions:
  • No resize needed (within 3840x3840)
  • Optimize to 85% quality
  • Strip metadata
✓ Optimized: 2341KB → 1234KB (-47%)

============================================
Summary:
  • Processed: 3 image(s)
  • Skipped: 0 image(s)
  • Total size: 9876KB → 4123KB (-58%)
```

## Git Integration

### Why Stage Files First?

The git-focused approach requires staging files with `git add .` because:

1. **Fresh Repositories**: `git status` only shows directories like `source/`, not individual files
2. **Respects .gitignore**: Staged files exclude gitignored items automatically
3. **Covers All Cases**: Works for new files, modified files, and fresh repositories
4. **Safe Processing**: Only optimizes files that will actually be tracked by git

### Workflow

```bash
# 1. Stage all trackable files
git add .

# 2. Optimize staged images
./optimize-images.sh --auto

# 3. Check results and commit
git status
git commit -m "Add optimized images"
```

### What Gets Processed

- ✅ **New images** in tracked directories
- ✅ **Modified images** that are already tracked
- ✅ **Staged images** after `git add`
- ❌ **Gitignored images** (build artifacts, generated files)
- ❌ **Unstaged images** (until you run `git add`)

## Safety Features

- **Non-destructive**: Modifies images in place but asks for confirmation in interactive mode
- **Error Handling**: Gracefully handles missing files and invalid images
- **Requirement Checking**: Verifies ImageMagick and git (if needed) are installed
- **Directory Validation**: Ensures target directory exists before processing

## Use Cases

### Web Development
- Optimize images before committing to git
- Reduce website loading times
- Maintain consistent image quality across projects

### Photography
- Batch process photos for web sharing
- Reduce file sizes for email or upload
- Maintain quality while reducing storage needs

### General File Management
- Clean up image directories
- Prepare images for sharing or archiving
- Standardize image sizes across collections

## Integration Examples

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for staged images and optimize them
staged_images=$(git diff --cached --name-only --diff-filter=A | grep -E '\.(jpg|jpeg|png)$')
if [ ! -z "$staged_images" ]; then
    echo "Optimizing staged images..."
    ./scripts/optimize-images.sh --auto
    # Re-stage the optimized images
    git add .
fi
```

### Build Process

```bash
# In your build script - process all images in source directory
./optimize-images.sh --all-images --auto src/images/
```

### Deployment Pipeline

```bash
# Before deployment
./optimize-images.sh --auto --quality 80 --max-size 2048 assets/
```

## Troubleshooting

### ImageMagick Not Found
```bash
# Install ImageMagick
sudo apt-get install imagemagick  # Ubuntu/Debian
brew install imagemagick          # macOS
```

### Permission Denied
```bash
# Make script executable
chmod +x optimize-images.sh
```

### Git Not Found (--git-only mode)
```bash
# Install git
sudo apt-get install git
```

## Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.

## License

This script is released under the MIT License. See LICENSE file for details.

## Author

Created for use in web development and photography workflows. Part of the BitToGit migration helper project suite.