#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT="$ROOT/src/Init.lua"
CONFIG="$ROOT/build/darklua.json"
DIST_DIR="$ROOT/dist"
TEMP_OUT="$DIST_DIR/temp.lua"
OUTPUT="$ROOT/dist/THubX.lua"

mkdir -p "$DIST_DIR"

if ! command -v darklua >/dev/null 2>&1; then
  echo "[ x ] 未找到 darklua"
  exit 1
fi

DATE=$(date '+%Y-%m-%d')

START=$(date +%s%N)
darklua process "$INPUT" "$TEMP_OUT" --config "$CONFIG"
END=$(date +%s%N)
TIME_MS=$(( (END - START) / 1000000 ))

{
  echo "--[["
  echo "  THubX | build $DATE"
  echo "  入口: loadstring(game:HttpGet(.../dist/THubX.lua))()"
  echo "  源码: src/ 多文件，产物: dist/ 单文件 (darklua bundle path mode)"
  echo "]]"
  echo ""
  cat "$TEMP_OUT"
} > "$OUTPUT"
rm -f "$TEMP_OUT"

SIZE_KB=$(($(wc -c < "$OUTPUT") / 1024))

echo ""
echo "[ ✓ ] THubX Build 完成"
echo "[ > ] Time: ${TIME_MS}ms"
echo "[ > ] Size: ${SIZE_KB}KB"
echo "[ > ] Output: dist/THubX.lua"
echo ""
