---
name: tinypng
description: Compress and optimize PNG, JPEG, WebP, and AVIF images with the TinyPNG/Tinify HTTP API using only curl and the TINYPNG_API_KEY environment variable. Use when Codex needs to shrink image files, optionally resize them, convert formats, or preserve metadata, especially when the user asks to compress an image with TinyPNG or Tinify.
---

# Tinypng

## Overview

Use this skill to compress local image files through the TinyPNG/Tinify HTTP API without installing SDKs or extra packages. Use the bundled shell script on macOS/Linux and the PowerShell script on Windows.

## Workflow

1. Confirm that `TINYPNG_API_KEY` is set in the current environment.
2. Run `scripts/tinypng.sh` on macOS/Linux or `scripts/tinypng.ps1` on Windows.
3. Pass only `--input` for default compression.
4. Add `--width`, `--height`, `--convert`, or `--preserve` only when the user explicitly asks for those operations.
5. Let the script create a sibling output file when `--output` is omitted.

Default behavior:

- Compress only.
- Keep the original format unless `--convert` is provided.
- Keep the original dimensions unless `--width` or `--height` is provided.
- Do not preserve metadata unless `--preserve` is provided.
- Do not overwrite the source file by default.

Resize behavior:

- If both `--width` and `--height` are provided, the script uses TinyPNG's `fit` resize mode.
- If only one dimension is provided, the script uses TinyPNG's `scale` resize mode because the HTTP API requires that for single-dimension resizing.

## User Usage Guide

Natural-language examples:

- "Compress this image with TinyPNG."
- "Compress this image and set the width to 128."
- "Compress this PNG and convert it to WebP."
- "Compress this JPEG and preserve the creation metadata."

Explicit skill examples:

- "Use `$tinypng` to compress `hero.png`."
- "Use `$tinypng` to compress `photo.jpg` and set width to 128."
- "Use `$tinypng` to convert `banner.png` to WebP."

Shell examples:

```bash
export TINYPNG_API_KEY="your-api-key"
./scripts/tinypng.sh --input ./hero.png
./scripts/tinypng.sh --input ./hero.png --width 128
./scripts/tinypng.sh --input ./banner.png --width 128 --height 128
./scripts/tinypng.sh --input ./banner.png --convert webp
./scripts/tinypng.sh --input ./photo.jpg --preserve creation,location
./scripts/tinypng.sh --input ./hero.png --output ./hero-optimized.png
```

PowerShell examples:

```powershell
$env:TINYPNG_API_KEY = "your-api-key"
powershell -ExecutionPolicy Bypass -File .\scripts\tinypng.ps1 --input .\hero.png
powershell -ExecutionPolicy Bypass -File .\scripts\tinypng.ps1 --input .\hero.png --width 128
powershell -ExecutionPolicy Bypass -File .\scripts\tinypng.ps1 --input .\banner.png --width 128 --height 128
powershell -ExecutionPolicy Bypass -File .\scripts\tinypng.ps1 --input .\banner.png --convert webp
powershell -ExecutionPolicy Bypass -File .\scripts\tinypng.ps1 --input .\photo.jpg --preserve creation,location
powershell -ExecutionPolicy Bypass -File .\scripts\tinypng.ps1 --input .\hero.png --output .\hero-optimized.png
```

## Script Details

Script entrypoints:

- `scripts/tinypng.sh`
- `scripts/tinypng.ps1`

Supported flags:

- `--input <file>`
- `--output <file>`
- `--width <n>`
- `--height <n>`
- `--convert <webp|avif|jpeg|png>`
- `--preserve <copyright,creation,location>`
- `--help`

Output naming:

- If `--output` is omitted, the script writes a sibling file with `.tinypng` inserted before the extension.
- If `--convert` is provided and `--output` is omitted, the generated file extension matches the requested format.

## Notes

- Require `curl` to be available in the environment.
- Read the API key from `TINYPNG_API_KEY`.
- Surface TinyPNG HTTP errors directly so the caller can diagnose auth, rate-limit, or request issues quickly.
