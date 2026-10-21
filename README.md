# fleet

Personal agent fleet: agent definitions and the shared prompts they run on. This repo is the source of truth; OpenCode discovers the agents via symlinks in `~/.config/opencode/agents/`.

## Agents

| Agent | Mode | Model | Notes |
|---|---|---|---|
| `black` | `primary` | `gianni-desktop/Qwen3.8-27B-UD-Q6_K` | Local Qwen 27B (OpenAI-compatible server at `gianni-desktop:8000`) |
| `blue` | `primary` | `opencode/deepseek-v4.1-flash-free` | Free OpenCode Zen DeepSeek |
| `reviewer` | `subagent` | `opencode/deepseek-v4.1-flash-free` | Reviews a PR and merges only a two-way door — see [Reviewing](#reviewing) |
| `retro` | `subagent` | `opencode/deepseek-v4.1-flash-free` | Runs the retro skill on a session and files findings as backlog tickets — see [Retro](#retro) |

`black` and `blue` are pure model switches — identical prompt, different model, so they are directly comparable. `reviewer` is dispatched for one PR and ends with a verdict; `retro` is dispatched for one session and ends by filing tickets.

## Dispatching

OpenCode v2.0.32 keeps agent and model as separate selections: switching agents does **not** switch the model. The `model:` frontmatter in these files is only honored when the agent runs as a subagent (task tool) or via a command bound to that agent. So dispatch with both:

- **TUI**: switch to `black`/`blue`, then pick its model once in the model selector. The TUI remembers the selection per agent, so later switches to the same agent keep it.
- **CLI**:

```sh
opencode run --agent black --model gianni-desktop/Qwen3.8-27B-UD-Q6_K "..."
opencode run --agent blue  --model opencode/deepseek-v4.1-flash-free "..."
```

Re-check this behavior if OpenCode is upgraded — newer versions have reworked agent switching and may couple the two.

## Terse

`terse/TERSE.md` is a harness-agnostic style prompt: bullets, no filler, technical content intact. On by default in every session of every harness, so it is not an agent. In OpenCode the `terse` plugin (`terse/opencode/plugin/`) appends it to the system prompt while the switch says on, and `/terse off` flips that switch; Claude Code and Codex reach it through a symlinked global rule.

Install and the savings caveats: [`terse/README.md`](terse/README.md).

## Install / re-link

```sh
ln -s ~/projects/fleet/black.md ~/.config/opencode/agents/black.md
ln -s ~/projects/fleet/blue.md ~/.config/opencode/agents/blue.md
ln -s ~/projects/fleet/reviewer.md ~/.config/opencode/agents/reviewer.md
ln -s ~/projects/fleet/retro.md ~/.config/opencode/agents/retro.md
```

Verify with `opencode api agent.list` — `black`, `blue`, `reviewer` and `retro` should appear with their models and colors.

## Reviewing

`reviewer` is a subagent: the trunk hands it a ticket whose PR is waiting for review, plus the PR number. It reads the diff, the checks and the ticket, reviews against the repo's `AGENTS.md`, ADRs and `GLOSSARY.md`, then puts the change in one of two classes. The rule is about what a revert costs.

- **Two-way door + low blast radius** — the change is revertible with one `git revert` (or by deleting what it added) and leaves nothing behind: no stored-data or schema change, no published contract, no release, nothing reaching past this repo. The reviewer approves, merges with `gh pr merge --merge` — a merge commit, never a squash, so the history a revert needs survives — and completes the ticket with the PR as evidence.
- **One-way / destructive / high blast radius** — a revert does not undo it, or it reaches past this repo: a schema or envelope change, a migration, deleting data, a published API, a release, branch policy. The reviewer comments the specific risks, sets the ticket `assignee human` + `refined`, and never merges.

Unsure goes to the second class. The author states the class in the PR body's `## Merge Danger` section (`Door:`, `Blast Radius:`); the reviewer verifies it against the diff rather than trusting it.

## Retro

`retro` is a subagent: the caller names a session and it reads the transcript (`opencode api session.message.list`), runs the retro skill's categories against it, and files each finding as a `backlog` ticket in that project's cycle lane. The tickets are the output; the report is a receipt.

- **The bar** — an anchor in the transcript, a named cost, and a next move someone can take without having been in the session. Generic advice, a preference with no cost, and anything an open ticket already covers is skipped and named.
- **Nothing else moves.** Always `backlog`, never assigned. It does not refine, dispatch, complete, or edit the code the session touched — a retro that fixes what it finds cannot report on it honestly.
- **Zero tickets is a valid result.** More than five from one session means the bar was lowered, not that the session was bad.

Its body is the retro skill plus the filing rules: the skill's last step presents candidates to the user, and this agent files them instead.

## Workflow

[WORKFLOW.md](WORKFLOW.md) is the end-to-end map: every agent's role in the ticket lifecycle, the handoffs between them, and the gaps where the fleet does not yet fully run on Tandem.

## Adding a new agent

1. Create `<name>.md` here — the filename becomes the agent name. Copy an existing file; frontmatter supports `description` (required), `mode` (`primary`/`subagent`/`all`), `model` (`provider/model`), `color`, `temperature`, `permission`.
2. Symlink it into `~/.config/opencode/agents/`.
3. Verify with `opencode api agent.list`.

## Not in this repo

`consolidator` is deliberately not here: it is Tandem-specific and lives as a real file in `~/.config/opencode/agents/`.
