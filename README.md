# agents

Personal OpenCode agent definitions. This repo is the source of truth; OpenCode discovers the agents via symlinks in `~/.config/opencode/agents/`.

## Agents

| Agent | Model | Notes |
|---|---|---|
| `black` | `gianni-desktop/Qwen3.8-27B-UD-Q6_K` | Local Qwen 27B (OpenAI-compatible server at `gianni-desktop:8000`) |
| `blue` | `opencode/deepseek-v4.1-flash-free` | Free OpenCode Zen DeepSeek |

Both are `primary` agents and pure model switches — identical prompt, different model, so they are directly comparable.

## Dispatching

OpenCode v2.0.32 keeps agent and model as separate selections: switching agents does **not** switch the model. The `model:` frontmatter in these files is only honored when the agent runs as a subagent (task tool) or via a command bound to that agent. So dispatch with both:

- **TUI**: switch to `black`/`blue`, then pick its model once in the model selector. The TUI remembers the selection per agent, so later switches to the same agent keep it.
- **CLI**:

```sh
opencode run --agent black --model gianni-desktop/Qwen3.8-27B-UD-Q6_K "..."
opencode run --agent blue  --model opencode/deepseek-v4.1-flash-free "..."
```

Re-check this behavior if OpenCode is upgraded — newer versions have reworked agent switching and may couple the two.

## Install / re-link

```sh
ln -s ~/projects/agents/black.md ~/.config/opencode/agents/black.md
ln -s ~/projects/agents/blue.md ~/.config/opencode/agents/blue.md
```

Verify with `opencode api agent.list` — `black` and `blue` should appear with their models and colors.

## Adding a new agent

1. Create `<name>.md` here — the filename becomes the agent name. Copy an existing file; frontmatter supports `description` (required), `mode` (`primary`/`subagent`/`all`), `model` (`provider/model`), `color`, `temperature`, `permission`.
2. Symlink it into `~/.config/opencode/agents/`.
3. Verify with `opencode api agent.list`.

## Not in this repo

`consolidator` is deliberately not here: it is Tandem-specific and lives as a real file in `~/.config/opencode/agents/`.
