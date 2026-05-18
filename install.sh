#!/usr/bin/env bash
set -euo pipefail

# subagent-pipeline installer
# Usage:  ./install.sh --cursor | --claude | --codex
# Run from the target project's root directory.
# Copies agents/, commands/, skills/ to the provider-specific path,
# and seeds docs/ + AGENTS.md if they don't already exist.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

usage() {
  cat <<'EOF'
Usage: install.sh [--cursor | --claude | --codex] [--target <path>] [--force]

Flags:
  --cursor     Install for Cursor (writes to .cursor/)
  --claude     Install for Claude Code (writes to .claude/)
  --codex      Install for Codex (writes to .codex/)
  --target     Target project root (default: current working dir)
  --force      Overwrite existing agent/command/skill files in the provider dir
               (does NOT overwrite docs/CONVENTIONS.md, docs/ARCHITECTURE.md,
                docs/adr/0001-*.md, or AGENTS.md — those are user-edited)
  -h, --help   Show this message

Examples:
  cd ~/work/my-project
  /path/to/subagent-pipeline/install.sh --cursor

  /path/to/subagent-pipeline/install.sh --claude --target ~/work/my-project
EOF
}

PROVIDER=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cursor)  PROVIDER="cursor"; shift ;;
    --claude)  PROVIDER="claude"; shift ;;
    --codex)   PROVIDER="codex";  shift ;;
    --target)  TARGET_DIR="$2";   shift 2 ;;
    --force)   FORCE=1;           shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$PROVIDER" ]]; then
  echo "Error: must pass exactly one of --cursor | --claude | --codex" >&2
  usage
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: target dir does not exist: $TARGET_DIR" >&2
  exit 1
fi

case "$PROVIDER" in
  cursor) PROVIDER_DIR="$TARGET_DIR/.cursor" ;;
  claude) PROVIDER_DIR="$TARGET_DIR/.claude" ;;
  codex)  PROVIDER_DIR="$TARGET_DIR/.codex"  ;;
esac

echo "Installing subagent-pipeline for $PROVIDER"
echo "  source:  $SCRIPT_DIR"
echo "  target:  $TARGET_DIR"
echo "  agents:  $PROVIDER_DIR/agents"
echo ""

# -----------------------------------------------------------------------------
# 1. Copy agents/, commands/, skills/ to .{provider}/
# -----------------------------------------------------------------------------

copy_tree() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [[ ! -d "$src" ]]; then
    echo "  (skip $label: source dir missing — $src)"
    return
  fi

  mkdir -p "$dst"

  if [[ "$FORCE" -eq 1 ]]; then
    cp -R "$src/." "$dst/"
    echo "  ✓ $label installed (forced overwrite)"
  else
    # Only copy files that don't already exist at the destination
    local copied=0
    local skipped=0
    while IFS= read -r -d '' file; do
      local rel="${file#$src/}"
      local target="$dst/$rel"
      if [[ -e "$target" ]]; then
        skipped=$((skipped + 1))
      else
        mkdir -p "$(dirname "$target")"
        cp "$file" "$target"
        copied=$((copied + 1))
      fi
    done < <(find "$src" -type f -print0)
    echo "  ✓ $label: $copied copied, $skipped skipped (already exist; pass --force to overwrite)"
  fi
}

copy_tree "$SCRIPT_DIR/agents"   "$PROVIDER_DIR/agents"   "agents"
copy_tree "$SCRIPT_DIR/commands" "$PROVIDER_DIR/commands" "commands"
copy_tree "$SCRIPT_DIR/skills"   "$PROVIDER_DIR/skills"   "skills"

# -----------------------------------------------------------------------------
# 2. Seed AGENTS.md (root) — only if missing
# -----------------------------------------------------------------------------

if [[ ! -f "$TARGET_DIR/AGENTS.md" ]]; then
  cat > "$TARGET_DIR/AGENTS.md" <<'EOF'
# AGENTS.md — <project name>

> Placeholder. Run `/onboarding` to fill this in.

## What this project is
<one paragraph: what the system does, who uses it>

## Stack
- Language:
- Framework:
- Database:
- Tests:
- Deploy:

## Convention chain
1. This file (`AGENTS.md`)
2. `docs/CONVENTIONS.md`
3. `docs/ARCHITECTURE.md`
4. `openapi.yaml` (optional; backend / full-stack only)
5. `docs/adr/*.md`

## How to invoke the pipeline
- `/spec-builder <JIRA-ID>` — produce SPEC.md
- `/planner for ticket <id>` — produce PLAN.md, stop for review
- `/implementer for ticket <id>` — code + IMPLEMENTATION_NOTES.md
- `/reviewer for ticket <id>` — cold-eyes REVIEW.md
- `/qa for ticket <id>` — tests + QA_REPORT.md
- `/feature-pipeline` — two-phase orchestrator with one stop at PLAN.md

Per-feature artifacts live in `agent-run/<ticket-id>/`.
EOF
  echo "  ✓ AGENTS.md (root) seeded"
else
  echo "  · AGENTS.md (root) already exists — leaving alone"
fi

# -----------------------------------------------------------------------------
# 3. Seed docs/ scaffolding — only if missing
# -----------------------------------------------------------------------------

mkdir -p "$TARGET_DIR/docs/adr" "$TARGET_DIR/docs/diagrams"

seed_doc() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "  ✓ $(basename "$dst") seeded"
  else
    echo "  · $(basename "$dst") already exists — leaving alone"
  fi
}

seed_doc "$SCRIPT_DIR/docs/CONVENTIONS.md"                    "$TARGET_DIR/docs/CONVENTIONS.md"
seed_doc "$SCRIPT_DIR/docs/ARCHITECTURE.md"                   "$TARGET_DIR/docs/ARCHITECTURE.md"
seed_doc "$SCRIPT_DIR/docs/adr/0001-record-architecture-decisions.md" \
         "$TARGET_DIR/docs/adr/0001-record-architecture-decisions.md"

if [[ ! -e "$TARGET_DIR/docs/diagrams/.gitkeep" ]]; then
  touch "$TARGET_DIR/docs/diagrams/.gitkeep"
fi

# -----------------------------------------------------------------------------
# 4. Ensure agent-run/ exists with .gitkeep so the path is real on day 1
# -----------------------------------------------------------------------------

mkdir -p "$TARGET_DIR/agent-run"
if [[ ! -e "$TARGET_DIR/agent-run/.gitkeep" ]]; then
  touch "$TARGET_DIR/agent-run/.gitkeep"
fi

# -----------------------------------------------------------------------------
# 5. Final hint
# -----------------------------------------------------------------------------

cat <<EOF

Install complete.

Next:
  1. Open this project in $PROVIDER.
  2. Invoke /onboarding to fill in AGENTS.md, docs/CONVENTIONS.md, docs/ARCHITECTURE.md.
  3. Start your first feature with /spec-builder <JIRA-ID>  or  /feature-pipeline.

Per-feature artifacts will land in: $TARGET_DIR/agent-run/<ticket-id>/
EOF
