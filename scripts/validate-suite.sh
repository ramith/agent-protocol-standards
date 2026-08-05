#!/usr/bin/env bash
# validate-suite.sh — mechanical gates for the agentic-identity skill suite.
# Grown alongside skill 1 (D6): each check was added when its convention got
# its first real instance. CI runs this advisorily; the DoD checkbox
# "validator green locally" is the real gate.
#
# Usage: scripts/validate-suite.sh [--verify-hashes]
#   --verify-hashes  re-fetch every source in each _source.md and compare
#                    SHA-256 (network required; used in QA runs, not CI).
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Suite skills live at the repo root (D3 amendment); identified by references/_source.md.
SKILLS_DIR="$ROOT"
PLAYBOOK="$ROOT/docs/skill-development-playbook.md"
VERIFY_HASHES=0
[ "${1:-}" = "--verify-hashes" ] && VERIFY_HASHES=1

errors=0
warnings=0
err()  { echo "  ✗ $1"; errors=$((errors + 1)); }
warn() { echo "  ⚠ $1"; warnings=$((warnings + 1)); }
ok()   { echo "  ✓ $1"; }

for dir in "$SKILLS_DIR"/*/; do
  name="$(basename "$dir")"
  skill_md="$dir/SKILL.md"

  # Suite skills are identified by a source register; others (e.g. bundled
  # third-party skills) are out of scope for these gates.
  [ -f "$dir/references/_source.md" ] || continue

  echo "── $name"

  # ── SKILL.md structural checks ──────────────────────────────────────────
  if [ ! -f "$skill_md" ]; then err "SKILL.md missing"; continue; fi

  lines=$(wc -l < "$skill_md" | tr -d ' ')
  if [ "$lines" -ge 500 ]; then err "SKILL.md is $lines lines (limit 500)"; else ok "SKILL.md $lines/500 lines"; fi

  head -n1 "$skill_md" | grep -q '^---$' || err "frontmatter missing (no leading ---)"
  grep -q '^description:' "$skill_md" || err "frontmatter: description missing"
  grep -q '^name:' "$skill_md" || warn "frontmatter: name missing (display label defaults to dir name)"

  grep -q 'PINNED STANDARD VERSIONS' "$skill_md" && ok "pinned-versions banner present" \
    || err "pinned-versions banner missing (P11)"
  grep -qE '^> \*\*⚠? ?QA:' "$skill_md" && ok "QA stamp present" \
    || err "QA stamp missing (qa-strategy: honest degraded mode)"
  grep -q 'staleness.sh' "$skill_md" && ok "staleness injection wired" \
    || err "staleness injection missing from SKILL.md"

  verified=0
  grep -qE '^> \*\*⚠? ?QA: UNVERIFIED' "$skill_md" || verified=1

  # ── source register ─────────────────────────────────────────────────────
  src="$dir/references/_source.md"
  rows=0; badrows=0
  while IFS='|' read -r _ id url rev fetched recheck latest sha _rest; do
    id=$(echo "$id" | tr -d ' '); fetched=$(echo "$fetched" | tr -d ' ')
    sha=$(echo "$sha" | tr -d ' '); url=$(echo "$url" | tr -d ' ')
    case "$fetched" in 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) continue ;; esac
    rows=$((rows + 1))
    echo "$sha" | grep -qE '^[a-f0-9]{64}$' || { err "_source.md: $id has no valid sha256"; badrows=$((badrows+1)); }
    if [ "$VERIFY_HASHES" -eq 1 ]; then
      actual=$(curl -sfL "$url" | shasum -a 256 | cut -d' ' -f1)
      if [ "$actual" = "$sha" ]; then ok "hash verified: $id"
      else err "HASH MISMATCH: $id (source revised or fetch differs — fork per qa-strategy)"; fi
    fi
  done < "$src"
  if [ "$rows" -eq 0 ]; then err "_source.md: no parseable source rows"; else ok "_source.md: $rows hash-pinned sources"; fi

  # ── staleness script ─────────────────────────────────────────────────────
  st="$dir/scripts/staleness.sh"
  if [ -x "$st" ]; then
    out=$("$st" 2>&1)
    case "$out" in
      *STALE*) warn "staleness: $out" ;;
      *"Sources OK"*) ok "staleness.sh runs clean" ;;
      *) err "staleness.sh unexpected output: $out" ;;
    esac
  else
    err "scripts/staleness.sh missing or not executable"
  fi

  # ── assertion IDs (once a checklist exists) ──────────────────────────────
  ids=$(grep -oE '\b[A-Z]{2,4}-[0-9]{3}\b' "$skill_md" | sort)
  if [ -n "$ids" ]; then
    dupes=$(echo "$ids" | uniq -d)
    [ -n "$dupes" ] && err "duplicate assertion IDs: $(echo "$dupes" | tr '\n' ' ')"
    prefix=$(echo "$ids" | head -1 | cut -d- -f1)
    grep -q "| $name | $prefix |" "$PLAYBOOK" \
      && ok "assertion prefix $prefix registered ($(echo "$ids" | uniq | wc -l | tr -d ' ') unique IDs)" \
      || err "assertion prefix $prefix not registered in playbook Part 4"
  elif [ "$verified" -eq 1 ]; then
    err "no assertion IDs found but skill claims verified"
  else
    warn "no assertion checklist yet (OK — skill is stamped UNVERIFIED)"
  fi

  # ── later-stage artifacts: hard-fail only for skills claiming verified ───
  for artifact in "evals/evals.json:eval set" "qa/verification-report.md:verification report"; do
    f="${artifact%%:*}"; label="${artifact#*:}"
    if [ -e "$dir/$f" ]; then ok "$label present"
    elif [ "$verified" -eq 1 ]; then err "$label missing but skill claims verified"
    else warn "$label not yet present (OK — skill is stamped UNVERIFIED)"
    fi
  done

  # ── verification-report freshness (anti-erosion, qa-strategy) ────────────
  vr="$dir/qa/verification-report.md"
  if [ -f "$vr" ]; then
    recorded=$(grep -oE 'SKILL.md sha256: [a-f0-9]{64}' "$vr" | grep -oE '[a-f0-9]{64}' | head -1)
    if [ -n "$recorded" ]; then
      current=$(shasum -a 256 "$skill_md" | cut -d' ' -f1)
      [ "$recorded" = "$current" ] && ok "verification report fresh (hash match)" \
        || err "VERIFICATION STALE: SKILL.md edited after verification (hash mismatch)"
    else
      warn "verification report records no SKILL.md hash"
    fi
  fi
done

echo ""
echo "validate-suite: $errors error(s), $warnings warning(s)"
[ "$errors" -eq 0 ] && echo "RESULT: GREEN" || echo "RESULT: RED"
exit "$errors"
