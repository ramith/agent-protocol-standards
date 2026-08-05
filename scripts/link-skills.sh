#!/bin/sh
# Creates git-ignored symlinks in .claude/skills/ pointing at the skill folders
# at the repo root, so Claude Code loads them during development (D3 amendment:
# root folders are the source of truth; Claude Code follows skill symlinks).
# Run once after cloning. Idempotent.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/.claude/skills"
linked=0
for dir in "$ROOT"/*/; do
  name="$(basename "$dir")"
  [ -f "$dir/references/_source.md" ] || continue   # suite skills only
  link="$ROOT/.claude/skills/$name"
  [ -L "$link" ] && rm "$link"
  [ -e "$link" ] && { echo "skip: $link exists and is not a symlink"; continue; }
  ln -s "../../$name" "$link"
  echo "linked: .claude/skills/$name -> ../../$name"
  linked=$((linked + 1))
done
echo "link-skills: $linked skill(s) linked"
