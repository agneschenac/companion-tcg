#!/bin/bash
# Resize images to 1500x1500 max, add watermark at center with 35% opacity,
# save to <folder>/processed/.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WATERMARK="$REPO_DIR/Watermark Companion.png"
MAX_DIM=1500
WATERMARK_WIDTH=500   # ~33% of MAX_DIM
OPACITY=0.20          # 0.0 to 1.0
QUALITY=85

if [ ! -f "$WATERMARK" ]; then
  echo "ERROR: watermark not found at $WATERMARK"
  exit 1
fi

process_folder() {
  local folder="$1"
  local in_dir="$REPO_DIR/$folder"
  local out_dir="$in_dir/processed"

  if [ ! -d "$in_dir" ]; then
    echo "Skipping $folder (not found)"
    return
  fi

  mkdir -p "$out_dir"
  local count=0
  local total
  total=$(find "$in_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l | tr -d ' ')

  echo "Processing $folder/ ($total files)..."
  for f in "$in_dir"/*.jpg "$in_dir"/*.jpeg "$in_dir"/*.png; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f")
    local stem="${name%.*}"
    local out="$out_dir/${stem}.jpg"

    if [ -f "$out" ]; then
      count=$((count + 1))
      printf "  [%d/%d] %s (skipped, already exists)\n" "$count" "$total" "$name"
      continue
    fi

    magick "$f" \
      -auto-orient \
      -resize "${MAX_DIM}x${MAX_DIM}>" \
      \( "$WATERMARK" -resize "${WATERMARK_WIDTH}x${WATERMARK_WIDTH}>" \
         -alpha set -channel A -evaluate multiply ${OPACITY} +channel \) \
      -gravity center -composite \
      -quality "$QUALITY" \
      -strip \
      "$out"

    count=$((count + 1))
    printf "  [%d/%d] %s\n" "$count" "$total" "$name"
  done
  echo "Done: $folder/ -> $out_dir"
}

process_folder "back"
process_folder "front"

echo "All done."
