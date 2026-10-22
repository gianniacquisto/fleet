# fleet

Personal agent fleet: the model-switch builders, and the map of the workflow they run in. The passes that run on Tandem — `refine`, `reviewer`, `retro`, `consolidator` — live in the Tandem repo, which owns the board and the bikeshed they act on; this repo holds `black` and `blue` (the same prompt, two models, opt-in) and `terse`, the style every prompt runs under. OpenCode discovers the agents through symlinks in `~/.config/opencode/agents/`.

## Agents

| Agent | Mode | Model | Defined in | Notes |
|---|---|---|---|---|
| `black` | `primary` | `gianni-desktop/Qwen3.8-27B-UD-Q6_K` | this repo | Local Qwen 27B (OpenAI-compatible server at `gianni-desktop:8000`) |
| `blue` | `primary` | `opencode/deepseek-v4.1-flash-free` | this repo | Free OpenCode Zen DeepSeek |
| `build` | `primary` | the session's | the harness (OpenCode) | The harness's default agent — the one a session runs when nothing names another |
| `general` | `subagent` | the session's | the harness (OpenCode) | The harness's generalist — the builder the board dispatches a buildable ticket to |
| `explore` | `subagent` | the session's | the harness (OpenCode) | The harness's read-only repo search |
| `refine` | `subagent` | — | the tandem repo | Grills a `backlog` ticket into a brief a builder can be handed; the triage pass |
| `reviewer` | `subagent` | — | the tandem repo | Reviews a PR and merges only a two-way door — see [Reviewing](#reviewing) |
| `retro` | `subagent` | — | the tandem repo | Runs the retro skill on a session and files findings as backlog tickets — see [Retro](#retro) |
| `consolidator` | `subagent` | — | the tandem repo | Folds the bikeshed's captures into the curated notes; on request only |

The roster of record is the [Roster](WORKFLOW.md#roster) in `WORKFLOW.md`; this table is the front page's summary of it.

`build`, `general` and `explore` are the harness's, not the fleet's: OpenCode ships them, so no file in this repo or the Tandem repo defines them, and none of the three names a model — each runs the model of the session it is in. The Tandem repo's `refine`, `reviewer` and `retro` name no model either, so they run on the host's default the same way.

`black` and `blue` are pure model switches — identical prompt, different model, so they are directly comparable. `refine` is dispatched for one ticket and ends with a brief; `reviewer` is dispatched for one PR and ends with a verdict; `retro` is dispatched for one session and ends by filing tickets.

**How the four Tandem passes are entered.** They are not host commands, and no repo ships a command file for them — what the Tandem repo holds are skills: `skills/tandem-board/` triages and dispatches, `skills/tandem-consolidate/` dispatches the `consolidator` agent, and the `retro` agent runs the categories in `skills/retro/`, a file it reads rather than a skill it invokes. The `refine` agent is dispatched by the board skill for a ticket that needs a spec, and the `reviewer` is dispatched by a session, not by a skill: each one's contract is its own prompt (`agents/refine.md`, `agents/reviewer.md` there), and the caller hands it a ticket id — plus a PR number for the reviewer. A host that wants its own shortcut binds one; the binding is the host's business.

The split is by ownership, not by kind: the passes that run on Tandem live in the Tandem repo (`agents/` there), because the board, the bikeshed and the ticket model they act on are Tandem's. The two that are only builders — one prompt, two models — stay here. Tandem's ADR 0026 (`docs/adr/0026-agent-prompts-and-portable-setup.md` in that repo) records the decision.

## Dispatching

OpenCode v2.0.32 keeps agent and model as separate selections: switching agents does **not** switch the model. The `model:` frontmatter in these files is only honored when the agent runs as a subagent (task tool) or via a command bound to that agent. So dispatch with both:

- **TUI**: switch to `black`/`blue`, then pick its model once in the model selector. The TUI remembers the selection per agent, so later switches to the same agent keep it. (Both are opt-in — link them first, see [Install](#install--re-link).)
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

The two builders are **opt-in**: nothing links them by default, because a host that carries them also carries two more agents to choose from than a machine that wants the Tandem workflow. Link them when you want the comparison arm:

```sh
# this repo, from its root
ln -s "$PWD/black.md" ~/.config/opencode/agents/black.md
ln -s "$PWD/blue.md" ~/.config/opencode/agents/blue.md
```

The passes that run on Tandem are installed by the Tandem repo, which owns them: `refine`, `reviewer`, `retro` and `consolidator`, and the skills and instructions they work with. The `tandem-setup` skill does it — ask your agent to set up Tandem. It lands with the next Tandem release (tandem PR #73) — until then, the prompts are in this repo's history and in the Tandem PR.

Verify with `opencode api agent.list` — `refine`, `reviewer`, `retro` and `consolidator` should appear with their models and colors, and `black` and `blue` only if you linked them.

## Reviewing

`reviewer` is a subagent — its prompt is in the Tandem repo, `agents/reviewer.md` there. The trunk hands it a ticket whose PR is waiting for review, plus the PR number. It reads the diff, the checks and the ticket, reviews against the repo's `AGENTS.md`, ADRs and `GLOSSARY.md`, then puts the change in one of two classes. The rule is about what a revert costs.

- **Two-way door + low blast radius** — the change is revertible with one `git revert` (or by deleting what it added) and leaves nothing behind: no stored-data or schema change, no published contract, no release, nothing reaching past this repo. The reviewer approves, merges with `gh pr merge --merge` — a merge commit, never a squash, so the history a revert needs survives — and completes the ticket with the PR as evidence.
- **One-way / destructive / high blast radius** — a revert does not undo it, or it reaches past this repo: a schema or envelope change, a migration, deleting data, a published API, a release, branch policy. The reviewer comments the specific risks, sets the ticket `assignee human` + `refined`, and never merges.

Unsure goes to the second class. The author states the class in the PR body's `## Merge Danger` section (`Door:`, `Blast Radius:`); the reviewer verifies it against the diff rather than trusting it.

## Retro

`retro` is a subagent — its prompt is in the Tandem repo, `agents/retro.md` there. The caller names a session and it reads the transcript (`opencode api session.message.list`), runs the retro skill's categories against it, and files each finding as a `backlog` ticket in that project's cycle lane. The tickets are the output; the report is a receipt.

- **The bar** — an anchor in the transcript, a named cost, and a next move someone can take without having been in the session. Generic advice, a preference with no cost, and anything an open ticket already covers is skipped and named.
- **Nothing else moves.** Always `backlog`, never assigned. It does not refine, dispatch, complete, or edit the code the session touched — a retro that fixes what it finds cannot report on it honestly.
- **Zero tickets is a valid result.** More than five from one session means the bar was lowered, not that the session was bad.

Its body is the retro skill plus the filing rules: the skill's last step presents candidates to the user, and this agent files them instead.

## Workflow

[WORKFLOW.md](WORKFLOW.md) is the end-to-end map: its [Roster](WORKFLOW.md#roster) is the roster of record, and the rest is every agent's role in the ticket lifecycle, the handoffs between them, and the gaps where the fleet does not yet fully run on Tandem.

## Adding a new agent

1. Create `<name>.md` here — the filename becomes the agent name. Copy an existing file; frontmatter supports `description` (required), `mode` (`primary`/`subagent`/`all`), `model` (`provider/model`), `color`, `temperature`, `permission`. A prompt that acts on Tandem's board or bikeshed belongs in the Tandem repo's `agents/`, not here.
2. Symlink it into `~/.config/opencode/agents/`.
3. Verify with `opencode api agent.list`.

## Not in this repo

The passes that run on Tandem — `refine`, `reviewer`, `retro` and `consolidator` — live in the Tandem repo, in `agents/` there, with the skills they run in `skills/` there. They read the board through `tandem-cli` and write into the bikeshed, so the project that owns those owns their prompts; Tandem's ADR 0026 records the decision. This repo keeps `black`, `blue` and `terse`.
