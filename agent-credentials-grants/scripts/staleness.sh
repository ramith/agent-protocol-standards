#!/bin/sh
# Source-freshness banner for this skill. Parses the table in references/_source.md.
# Output is injected into the skill content at every invocation (playbook D4/P11).
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DIR/references/_source.md"
[ -f "$SRC" ] || { echo "STALENESS CHECK UNAVAILABLE: references/_source.md missing"; exit 0; }

now=$(date +%s)
stale=0
oldest=0
count=0

while IFS='|' read -r _ id _url _rev fetched recheck _rest; do
  id=$(printf '%s' "$id" | tr -d ' ')
  fetched=$(printf '%s' "$fetched" | tr -d ' ')
  recheck=$(printf '%s' "$recheck" | tr -d ' ')
  case "$fetched" in
    20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) continue ;;
  esac
  count=$((count + 1))
  [ "$recheck" = "0" ] && continue
  f=$(date -j -f "%Y-%m-%d" "$fetched" +%s 2>/dev/null || date -d "$fetched" +%s 2>/dev/null) || continue
  age=$(( (now - f) / 86400 ))
  [ "$age" -gt "$oldest" ] && oldest=$age
  if [ "$age" -gt "$recheck" ]; then
    echo "STALE: $id fetched $fetched (${age}d old > ${recheck}d recheck window) — re-fetch and diff before answering version-sensitive questions."
    stale=1
  fi
done < "$SRC"

if [ "$count" -eq 0 ]; then
  echo "STALENESS CHECK UNAVAILABLE: no parseable source rows in _source.md"
elif [ "$stale" -eq 0 ]; then
  echo "Sources OK (${count} pinned; oldest re-checkable fetch ${oldest}d old). Register: references/_source.md"
fi
