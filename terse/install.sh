#!/usr/bin/env bash
# Link TERSE.md into every harness found on this machine. Idempotent; never overwrites.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/TERSE.md"
out() { printf '  %s\n' "$*"; }

link() { # link <source> <target> <label>
  local src=$1 target=$2 label=$3
  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$src" ]; then
      out "ok       $label"
    else
      out "skip     $label (symlink to elsewhere)"
    fi
    return
  fi
  if [ -e "$target" ]; then
    out "skip     $label (real file exists — merge TERSE.md manually)"
    return
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$src" "$target"
  out "linked   $label"
}

echo "terse"

# Claude Code: user-level rules load in every session, every project.
if [ -d "$HOME/.claude" ]; then
  link "$SRC" "$HOME/.claude/rules/terse.md" "~/.claude/rules/terse.md"
fi

# Codex: one global instruction file, no import syntax.
if [ -d "$HOME/.codex" ]; then
  link "$SRC" "$HOME/.codex/AGENTS.md" "~/.codex/AGENTS.md"
fi

# OpenCode: config can reference the file directly, so only report.
cfg=""
for candidate in "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.json"; do
  [ -f "$candidate" ] && cfg=$candidate && break
done
if [ -n "$cfg" ]; then
  if grep -q "TERSE.md" "$cfg"; then
    out "ok       opencode.json instructions"
  else
    out "manual   add \"$SRC\" to the instructions array in $cfg"
  fi
fi

# OpenCode escapes: the /terse command and the terse agent, symlinked like the rest of the fleet.
if [ -d "$HOME/.config/opencode" ]; then
  here=$(cd "$(dirname "$SRC")" && pwd)
  link "$here/opencode/commands/terse.md" "$HOME/.config/opencode/commands/terse.md" "~/.config/opencode/commands/terse.md"
  link "$here/opencode/agents/terse.md" "$HOME/.config/opencode/agents/terse.md" "~/.config/opencode/agents/terse.md"
fi

echo "restart any running session to pick it up."
