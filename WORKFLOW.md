# Workflow

The fleet works in tandem with **Tandem**: the board (`tandem-cli todo …`) is the queue, the bikeshed (`~/.tandem/bikeshed/`) is the memory, and the agents below are the only actors. This file is the map of that: who does what, at which gate, and what each handoff passes. The ticket model, its gates, and the board skill live in the Tandem repo; this file names the fleet's actors against them.

## Roster

| Agent | Mode | Role in the workflow | Defined in |
|---|---|---|---|
| `black` | primary, local Qwen 27B | builder; the comparison arm — one prompt, two models | this repo |
| `blue` | primary, DeepSeek v4.1 flash (free) | builder; the comparison arm | this repo |
| `general` | subagent, harness built-in | builder dispatched for one ticket; multi-step work | OpenCode |
| `explore` | subagent, harness built-in | read-only, fast repo search | OpenCode |
| `reviewer` | subagent, DeepSeek | the review gate; merges two-way doors | this repo |
| `retro` | subagent, DeepSeek | post-session pass; files `backlog` tickets | this repo |
| `consolidator` | subagent | the sole writer of the curated bikeshed notes; on request only | the host, deliberately outside this repo |

`terse` is not an agent: a request-time behaviour (a plugin plus a switch) that every prompt above runs under.

## The passes

One unit of work, end to end:

1. **Capture** — any agent, any time. Every session files its session ticket at start (`Session — <project> · <session-id>`), files a `note capture` at each non-obvious decision or gotcha, and closes the ticket at the end with what it did.
2. **Triage** — the dispatcher pass (`/board`, any primary agent with the `tandem-board` skill). `backlog` → `refined` by grilling; `refined` with no open question and no human-only decision → `ready`; human-only → escalated (`refined`, `assignee human`). One pass, one capture.
3. **Dispatch** — the dispatcher claims a `ready` ticket (`in-progress` + `assignee`) and hands the builder **the ticket id and description only**. The builder orients itself (`AGENTS.md`, the bikeshed, `todo list`), works in a branch or worktree, verifies, opens the PR, files captures, and ends with one `work` capture.
4. **Review** — the `reviewer` subagent reads the ticket, the diff, the checks, the repo's rules, and the PR's `## Merge Danger` claim. Two-way door + low blast radius → merge commit, then complete the ticket. One-way or high → escalate to the human with `file:line` risks. Cannot merge this pass → `blocked`, stays with its author.
5. **Retro** — the `retro` subagent over a named session; each finding that clears the bar becomes a `backlog` ticket in the project's lane. Zero tickets is valid. The trigger is not yet defined — see Gaps.
6. **Consolidate** — the `consolidator` subagent, on the human's request only (`/consolidate`): folds the project's raw captures into the curated notes and archives the consumed. Never automatic, never at session close.

## Handoffs

What crosses each boundary:

- **Dispatcher → builder** — the ticket id and description only. Restating memory in the brief is how two versions of the truth start.
- **Builder → reviewer** — a PR whose body carries the `## Merge Danger` claim (`Door:`, `Blast Radius:`) and the evidence (`## Progress`). The reviewer verifies the claim against the diff; it is a claim, not evidence.
- **Reviewer → dispatcher** — one verdict line (`VERDICT: merged | escalated | blocked — …`) plus what changed in the store.
- **Retro → the board** — `backlog` tickets in the project's lane; the report is a receipt. Nothing else moves.
- **Consolidator → the bikeshed** — curated notes only. Raw captures are create-only; archiving a consumed one is a `mv`, not an edit.

## Completion

The actor holding the evidence completes the ticket:

- **Merged PR** → the reviewer completes it, having read the merge commit back.
- **Non-PR outcome** (a filed ticket, a recorded answer, a changed file) → the dispatcher verifies the evidence, then completes.
- **Human decision** → the answering pass completes it once the `## Answer` is in the description.

This reconciles the two current statements — the reviewer's own prompt completes what it merges, and the board skill has the root verify then complete — see Gaps.

## Memory substrate

- **Sessions record themselves** — the session ticket at start and end, captures in between, one `work` capture on the floor.
- **Curated notes have exactly one writer** — the consolidator, run on request.
- **Orientation** for a new session — the bikeshed `Index` → the project's curated note → `todo list`, or the `/handoff` block for a paste-ready cut.

## Gaps (2026-10-21)

Each is filed as a `backlog` ticket in the `fleet` lane; this section is the summary.

1. **The builder prompts carry no PR contract.** `reviewer.md` states the whole contract (the `## Merge Danger` claim, the merge-commit rule, the evidence) and `black`/`blue` state none of it. A missing claim forces the reviewer to guess the class, and every builder re-derives the contract from the README. Cost: the handoff depends on the builder having happened to read. Next move: put the contract in the shared builder prompt — or decide deliberately that the project's `AGENTS.md` delivers it, so the fleet prompts stay host-agnostic.
2. **The fleet repo has no `AGENTS.md`; the protocol arrives through host glue.** Fleet sessions run the memory and session-ticket rules because `~/.config/opencode/opencode.json` points `instructions` at `~/projects/tandem/AGENTS.md` — another project's file, invisible to a fresh clone and to any other host. Cost: the fleet declares nothing about itself; on a host without that entry, fleet sessions run without the protocol. Next move: an `AGENTS.md` in this repo carrying the fleet's own rules.
3. **Completion ownership is stated twice, differently.** `reviewer.md` (the two-way action) completes the ticket it merges; the board skill's dispatch step has the root verify the evidence, then complete. Cost: a double completion, or a ticket left `in-progress` at the handoff. Next move: one rule in both documents — the actor holding the evidence completes (as stated in Completion above).
4. **The host command bindings are untracked.** `/board`, `/handoff` and `/consolidate` are real files in `~/.config/opencode/commands/`, not symlinks into this repo, so the workflow's entry points do not survive a fresh clone or a host move — and the README's "Not in this repo" names only the consolidator. Cost: the map of the fleet is incomplete exactly where the fleet is entered. Next move: track the three files here and symlink them (as `terse` is), or list them under "Not in this repo" with the reason.
5. **The retro trigger is undefined.** `retro` is dispatchable, but nothing names when a retro runs — session end, a long session, or the human's call. Cost: it never runs, or it runs twice over the same session. Next move: a rule in this file and the board skill.
6. **The roster of record omits the built-ins and the bindings.** The README's Agents table lists only the four fleet-defined agents, while the board already carries `general` as an assignee and the commands above are real entry points. Cost: a fresh session cannot map an `assignee: general` ticket or a `/board` run to anything in the repo. Next move: extend the table or point it at the Roster above.

## Deliberate boundaries

- `consolidator` is out of this repo by decision (2026-10-19): its job is the Tandem saddlebag, so it lives with that protocol.
- `black` and `blue` are one prompt, two models — a prompt edit lands identically in both, and the pair isolates the model's effect.
- `main` is protected server-side: PR required, merge commits only, force pushes refused. A fresh clone gets GitHub's rule and nothing else.
