# terse

One prompt, injected into every session of every harness. Bullets, no filler, technical content intact.

Inspired by [caveman](https://github.com/JuliusBrussee/caveman) — same goal, opposite persona. Caveman drops grammar to save tokens. This drops words and keeps the grammar, because broken English costs accuracy and goodwill.

| | |
|---|---|
| Normal | "The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle." |
| Terse | "New object ref each render. Inline object prop = new prop identity = re-render. Wrap in `useMemo`." |

## What it is

`TERSE.md` is the whole thing — plain Markdown, no frontmatter, no harness-specific syntax. Each harness has one slot for global instructions; point that slot at this file.

## Install

Verified paths; `install.sh` does the symlinks and prints the rest.

| Harness | Mechanism | Path |
|---|---|---|
| **OpenCode** | `instructions` array in config (native include, no copy) | `~/.config/opencode/opencode.json` |
| **Claude Code** | user-level rules, loaded every session, all projects | `~/.claude/rules/terse.md` |
| **Codex** | global `AGENTS.md` | `~/.codex/AGENTS.md` |

OpenCode — add to `~/.config/opencode/opencode.json`:

```jsonc
"instructions": [
  "~/projects/fleet/terse/TERSE.md"
],
```

Claude Code and Codex — symlink, so edits here apply everywhere:

```sh
ln -s ~/projects/fleet/terse/TERSE.md ~/.claude/rules/terse.md
ln -s ~/projects/fleet/terse/TERSE.md ~/.codex/AGENTS.md   # only if you have no global AGENTS.md
```

Codex reads a single global file and has no import syntax. If `~/.codex/AGENTS.md` already exists, paste the body of `TERSE.md` into it under a `## Style` heading instead of replacing it.

Other harnesses take the same shape — a global instruction file or rule that loads at session start: Gemini CLI (`~/.gemini/GEMINI.md`), Cursor (user rules, or `.cursor/rules/terse.mdc` with `alwaysApply: true`), Copilot (`.github/copilot-instructions.md`). Not verified here; check the path before trusting it.

## Why instruction files and not a skill or agent

- **Always on.** A global instruction file loads at every session start in every harness. A skill loads when the model decides to call it — measurably unreliable.
- **Portable.** Every harness has this slot. Only some have agents, and each agent format differs.
- **Additive.** It sits alongside the harness's own prompt rather than replacing it, so you keep the tool guidance the vendor tuned.

## Honest math

- **Output only.** This changes nothing about what the agent reads. Input is usually the bigger half of a coding bill.
- **Tool payloads don't shrink.** Diffs, file writes and command output are most of a coding agent's output tokens; a style rule can't touch them.
- **The rule itself costs input.** ~300 tokens on every request, forever. Cheaper than caveman's ~1,000, but not free.
- **Expect low single digits off the total bill.** The 65–75% figure from caveman's benchmark is prose-only, on prose-heavy prompts.

Cheaper wins first: fewer round trips, read less, don't re-ask.
