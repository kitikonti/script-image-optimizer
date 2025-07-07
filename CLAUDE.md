# Claude Development Notes

This file contains important workflow instructions for Claude (AI assistant) to follow when working with projects that use the image optimization script.

## Image Optimization Workflow for Claude

### MANDATORY: Before Committing Images

**IMPORTANT: Always check for and optimize images before committing changes.**

When working on projects that contain image files, Claude MUST follow this workflow:

#### 1. Check for New/Modified Images

Before any commit operations, check for image files:

```bash
# Check if there are any image files that need optimization
find . -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | head -5
```

#### 2. Ask User About Image Optimization

If images are found, ALWAYS ask the user:

```
Found X image files that may need optimization:
- path/to/image1.jpg
- path/to/image2.png

These images should be optimized before committing to:
• Reduce file sizes and prevent repository bloat
• Resize large images to reasonable dimensions
• Strip metadata for privacy and size reduction

Would you like me to run the image optimization script?
Options:
1. Yes - Run optimization automatically
2. Manual - You'll run it yourself
3. Skip - Commit without optimization (not recommended)
```

#### 3. Run Image Optimization (if approved)

If user approves, run the optimization:

```bash
# For git repositories (recommended - respects .gitignore)
git add .
./optimize-images.sh --git-only --auto

# Or for simple processing (all images)
./optimize-images.sh --auto

# Or if script is in different location
./scripts/optimize-images.sh --git-only --auto
```

#### 4. Verify Results

After optimization, show the results to the user:

```bash
# Check what changed
git status

# Show file size differences if helpful
git diff --stat
```

### When to Apply This Workflow

Apply this workflow in these situations:

1. **Before any git commit** that includes image files
2. **After copying/adding new images** to a project
3. **When images are modified** or replaced
4. **During project migration** (like Bitbucket to GitHub)
5. **When setting up image optimization** in a new project

### Project Integration

#### For New Projects

When setting up image optimization in a project:

1. Copy the `optimize-images.sh` script to the project root or `scripts/` directory
2. Make it executable: `chmod +x optimize-images.sh`
3. Add this workflow to the project's CLAUDE.md file
4. Document the script usage in README.md

#### Script Location

The script can be located in:
- Project root: `./optimize-images.sh`
- Scripts directory: `./scripts/optimize-images.sh`
- As a git submodule or copied from the standalone repository

### Example Messages

#### Finding Images Message
```
I found 3 image files in this commit:
- source/img/hero-image.jpg (2.4MB, 5000x3000px)
- assets/photo.png (1.8MB, 4200x2800px)  
- content/screenshot.jpg (900KB, 2400x1600px)

These should be optimized before committing. The script will:
• Resize images >3840px to fit within 3840x3840
• Compress to 85% quality
• Strip metadata

Run image optimization?
1. Git mode (recommended - respects .gitignore)
2. Process all images
3. Skip optimization

Choice (1/2/3):
```

#### Success Message
```
✅ Image optimization completed:
• Processed: 3 images
• Total size reduction: 4.1MB → 2.3MB (-44%)
• All images now optimized for web use
• Mode: Git-aware (respects .gitignore)

Files are ready for commit.
```

### Error Handling

If the optimization script is not found:

```
Image optimization script not found at ./optimize-images.sh

Options:
1. Download from: https://github.com/kitikonti/script-image-optimizer
2. Skip optimization for now (not recommended)
3. Process images manually

Would you like me to download the script or proceed without optimization?
```

## Integration with Other Tools

### Pre-commit Hooks

For projects using pre-commit hooks, the workflow can be automated:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for staged images
staged_images=$(git diff --cached --name-only --diff-filter=A | grep -E '\\.(jpg|jpeg|png)$')

if [ ! -z "$staged_images" ]; then
    echo "Optimizing staged images..."
    ./optimize-images.sh --git-only --auto
    git add .  # Re-stage optimized images
fi
```

### Build Processes

For projects with build processes, add image optimization as a build step:

```bash
# In package.json scripts or Makefile
"prebuild": "./optimize-images.sh --auto src/images/"
```

## Reference Links

- **Script Repository**: https://github.com/kitikonti/script-image-optimizer
- **ImageMagick Installation**: Required dependency for the script
- **Documentation**: Full usage examples in repository README.md

---

**Note to Claude**: This workflow prevents repository bloat and ensures optimal image sizes. Always prioritize image optimization in web development projects, as large unoptimized images significantly impact loading performance and repository size.