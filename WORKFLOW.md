# Workflow

The fleet works in tandem with **Tandem**: the board (`tandem-cli todo …`) is the queue, the bikeshed (`~/.tandem/bikeshed/`) is the memory, and the agents below and the human are the actors. This file is the map of that: who does what, at which gate, and what each handoff passes. The ticket model, its gates, and the board skill live in the Tandem repo; this file names the fleet's actors against them.

## Roster

| Agent | Mode | Role in the workflow | Defined in |
|---|---|---|---|
| `black` | primary, local Qwen 27B | builder; the comparison arm — one prompt, two models | this repo |
| `blue` | primary, DeepSeek v4.1 flash (free) | builder; the comparison arm | this repo |
| `build` | primary, harness built-in | the host's default agent — the one a session runs when nothing names another | OpenCode |
| `general` | subagent, harness built-in | builder dispatched for one ticket; multi-step work | OpenCode |
| `explore` | subagent, harness built-in | read-only, fast repo search | OpenCode |
| `refine` | subagent, DeepSeek | the triage pass; a `backlog` ticket into a brief a builder can be handed | the tandem repo |
| `reviewer` | subagent, DeepSeek | the review gate; merges two-way doors | the tandem repo |
| `retro` | subagent, DeepSeek | post-session pass; files `backlog` tickets | the tandem repo |
| `consolidator` | subagent | the sole writer of the curated bikeshed notes; on request only | the tandem repo |

`terse` is not an agent: a request-time behaviour (a plugin plus a switch) that every prompt above runs under.

A prompt's home is the project that owns its job, so the four passes that run on Tandem — `refine`, `reviewer`, `retro`, `consolidator` — live in the Tandem repo's `agents/`, and this repo holds the two builders and the style. Tandem's ADR 0026 records it. The two builders are **opt-in**: nothing links them into a host by default, because a host that carries them carries two more agents to choose from than a machine that wants the Tandem workflow.

## The passes

One unit of work, end to end:

1. **Capture** — any agent, any time. Every session files its session ticket at start (`Session — <project> · <session-id>`) with a brief — what the session is for and what done looks like — files a `note capture` at each non-obvious decision or gotcha, and closes the ticket at the end with the outcome appended below the brief. The session ticket is work, not a log entry: a board pass refines it and moves it like any other ticket (Tandem ADR 0024). Empty stdin clears a description, so never close a ticket with an empty body — when there is no outcome to record, close it with `todo complete`.
2. **Triage** — the dispatcher pass (the `tandem-board` skill, bound as `/board` on some hosts). `backlog` → `refined` by grilling; `refined` with no open question and no human-only decision → `ready`; human-only → escalated (`refined`, `assignee human`). One pass, one capture. A ticket that needs a spec goes to the `refine` agent: it runs the same grilling, writes the spec in the board's shape, and splits a big spec into one-session tickets. A session ticket whose session has ended is stale work and joins this queue: the session id in its title settles liveness — `opencode api session.list` shows each session's `outcome` and `time.updated`. A session updated seconds ago is running; a finished one carries an `outcome` of `succeeded`, `failed` or `interrupted`. Neither signal is exact alone — `null` proves nothing, and a resumed session keeps the outcome it had — so read both. A ticket whose session is live belongs to that session and is left alone; a quiet session is not a dead one, so the board's "a claim is not a stall" rule governs the borderline.
3. **Dispatch** — the dispatcher claims a `ready` ticket (`in-progress` + `assignee`) and hands the builder **the ticket id and description only**. The builder orients itself (`AGENTS.md`, the bikeshed, `todo list`), works in a branch or worktree, verifies, opens the PR, files captures, and ends with one `work` capture.
4. **Review** — the `reviewer` subagent reads the ticket, the diff, the checks, the repo's rules, and the PR's `## Merge Danger` claim. Two-way door + low blast radius → merge commit, then complete the ticket. One-way or high → escalate to the human with `file:line` risks. Cannot merge this pass → `blocked`, stays with its author.
5. **Retro** — the `retro` subagent over a named session; each finding that clears the bar becomes a `backlog` ticket in the project's lane. Zero tickets is valid. The trigger:
   - **The rule.** A retro runs on the human's request, and at the end of a session whose work landed — a merged PR or a completed ticket. A session that only read, planned or filed a capture is not retro'd: there is nothing in its transcript to find. The caller dispatches it: the dispatch step, for the session whose work landed, and the human, for a request. One retro per session.
   - The bar is what makes the automatic case safe: an anchor, a named cost and an owner's next move, and "zero tickets is a valid result" — a session with no finding files nothing; a session with a finding gets it filed.
6. **Consolidate** — the `consolidator` subagent, on the human's request only (the `tandem-consolidate` skill dispatches it): folds the project's raw captures into the curated notes and archives the consumed. Never automatic, never at session close.

## Handoffs

What crosses each boundary:

- **Dispatcher → builder** — the ticket id and description only. Restating memory in the brief is how two versions of the truth start.
- **Builder → reviewer** — a PR whose body carries the `## Merge Danger` claim (`Door:`, `Blast Radius:`) and the evidence (`## Progress`). The reviewer verifies the claim against the diff; it is a claim, not evidence. The `## Progress` section is this repo's convention, not one any builder prompt requires — see Gap 1.
- **Reviewer → dispatcher** — one verdict line (`VERDICT: merged | escalated | blocked — …`) plus what changed in the store.
- **Retro → the board** — `backlog` tickets in the project's lane; the report is a receipt. Nothing else moves.
- **Consolidator → the bikeshed** — curated notes only. Raw captures are create-only; archiving a consumed one is a `mv`, not an edit.

## Completion

The actor holding the evidence completes the ticket:

- **Merged PR** → the reviewer completes it, having read the merge commit back.
- **Non-PR outcome** (a filed ticket, a recorded answer, a changed file) → the dispatcher verifies the evidence, then completes.
- **Human decision** → the answering pass completes it once the `## Answer` is in the description.

The two current statements differ — the reviewer's own prompt completes what it merges, and the board skill has the root verify then complete — so the rule above is the proposal that closes Gap 3, not a description of today's behaviour.

## Memory substrate

- **Sessions record themselves** — the session ticket at start and end, captures in between, one `work` capture on the floor. The ticket carries a brief, gains the outcome by appending, and goes through the board like any other ticket.
- **Curated notes have exactly one writer** — the consolidator, run on request.
- **Orientation** for a new session — the bikeshed `Index` → the project's curated note → `todo list`, or the `tandem-handoff` block (bound as `/handoff` on some hosts) for a paste-ready cut.

## Gaps (2026-10-21)

Each gap is filed as a ticket — in the `fleet` lane for this repo's own gaps, in the `Tandem` lane for the two still open there (`5621FB91`, `7FFD7CD7`); the rest are closed. This section is the summary.

1. **The builder prompts carry no PR contract.** `reviewer.md` (in the Tandem repo now) states the whole contract (the `## Merge Danger` claim, the merge-commit rule, the evidence) and `black`/`blue` state none of it. A missing claim forces the reviewer to guess the class, and every builder re-derives the contract from the README. Cost: the handoff depends on the builder having happened to read. Next move: put the contract in the shared builder prompt — or decide deliberately that the project's `AGENTS.md` delivers it, so the fleet prompts stay host-agnostic.
2. ~~**The fleet repo has no `AGENTS.md`; the protocol arrives through host glue.**~~ **Closed 2026-10-21 by PR #16 (`3245358`).** Fleet sessions ran the memory and session-ticket rules because the host's `~/.config/opencode/AGENTS.md` was a link to the Tandem repo's `AGENTS.md` — another project's file, invisible to a fresh clone and to any other host. The repo now carries its own `AGENTS.md` — the memory protocol, the session-ticket rules, the pointer to `WORKFLOW.md` — so a fresh clone declares the fleet's rules and needs no glue. The live host on this Mac still serves the Tandem repo's file; that link is the host's, not the repo's. Filed as `70CE530F`, now `done`. The lesson it carries: **the working tree is deployment** — a merged change is not a live one until the checkout that hosts the config moves.
3. **Completion ownership is stated twice, differently.** `reviewer.md` (the two-way action) completes the ticket it merges; the board skill's dispatch step has the root verify the evidence, then complete. Cost: a double completion, or a ticket left `in-progress` at the handoff. Next move: one rule in both documents — the actor holding the evidence completes (as stated in Completion above).
4. ~~**The host command bindings are untracked.**~~ **Closed 2026-10-21 by the move into Tandem.** `/board`, `/handoff` and `/consolidate` were real files in `~/.config/opencode/commands/`, tracked by nothing, and the gap offered two ways out: track them here, or list them under "Not in this repo". The answer was a third: the passes are **skills** in the Tandem repo (`skills/tandem-board/`, `skills/tandem-handoff/`, `skills/tandem-consolidate/`), each model-invocable, so a host that is asked for the pass reaches it — and no repo ships a command file. `/consolidate`, the one that force-bound a host file to an agent, became `skills/tandem-consolidate/`, which dispatches the `consolidator` agent. A host may still bind its own command; the binding is the host's business. Filed as `171B5FD9`, now `done`.
5. ~~**The retro trigger is undefined.**~~ **Closed 2026-10-21 by the rule in pass 5, in the same words as the board skill's dispatch step.** `retro` is dispatchable, but nothing named when a retro runs — session end, a long session, or the human's call. Cost: it never ran, or it ran twice over the same session. The rule now names both triggers and the dispatcher: a retro runs on the human's request, and at the end of a session whose work landed — a merged PR or a completed ticket — and the caller dispatches it, once per session. Filed as `FA5AF818`, now `in-review`.
6. ~~**The roster of record omits the built-ins and the bindings.**~~ **Closed 2026-10-21 by the README's roster.** The Agents table now carries `general` and `explore` beside the five it already had — the harness's, not the fleet's, with `general` named as what the board dispatches a buildable ticket to — and points at the Roster above as the roster of record. The three Tandem passes are named as the skills in the Tandem repo that dispatch their agents, not as host command files. Filed as `B49EE1B7`.
7. ~~**The live skills on this Mac are a stale untracked copy of the tandem `main` checkout.**~~ **Closed 2026-10-21 by v0.15.0.** `~/.config/opencode/opencode.json` pointed `skills` at the tandem checkout's `skills/` — the `main` checkout, which was behind `dev` with `skills/tandem-board/` untracked there, and whose live `AGENTS.md` and live board skill disagreed with each other about the old `Session —` skip. The release moved `main` forward, the checkout fast-forwarded to it, and the skill files are tracked now. Both live files carry ADR 0024. Filed as `DDC3811D`, now `done`. The lesson it carries: **the working tree is deployment** — a merged change is not a live one until the checkout that hosts the config moves. *Amended 2026-10-21:* the route changed again — the host's `opencode.json` no longer lists the checkout at all; the Tandem repo's `tandem-setup` skill has an agent link the skills, the agent prompts and the repo's `AGENTS.md` into `~/.config/opencode/`, so the same lesson now reads as *the link is the deployment*.
8. **The CLI clears a description on empty stdin.** `todo set --description -` with an empty pipe normalises the body to nothing and wipes the description, exit 0, no warning — confirmed on a throwaway home. The session-ticket protocol depends on that description, so this is the one CLI behaviour that can destroy what it preserves. Filed in the `Tandem` lane as `5621FB91`. Next move: make an empty `--description -` a domain failure, as `todo comment add` already does for an empty body.
9. ~~**The installed build is behind the source on `in-review`.**~~ **Closed 2026-10-21 by v0.15.0.** The tandem source carried the sixth `Status` since `562b69a` (ADR 0017) while the installed build was 0.14.0, tagged two hours earlier, with five: `todo set --status in-review` was refused, and a `todos.json` holding `"status": "in-review"` read back as `backlog` through it. The release and install landed — `v0.15.0` is green on `7b86ab8`, `main` is at the tag, the Mac runs 0.15.0, and `todo set --status in-review` now works against the real store. Filed as `ED140046`, now `done`. The lesson it carries is the one worth keeping: before writing a gap that says a tool lacks a capability, check the **source** and the **installed build** separately — they differ by a release, and only one of them is what an agent can change.
10. **`tandem/dev` requires one approving review, which one identity cannot give.** The reviewer and the human share a GitHub account, so GitHub refuses an author approving their own PR and the count is unsatisfiable. Every agent-driven merge into `dev` therefore waits for the human with `--admin` — which the reviewer is forbidden to use. The fleet's own `main` requires **zero** approvals for exactly this reason, so the two repos differ on the same decision. Filed in the `Tandem` lane as `7FFD7CD7`. Next move: decide whether `dev` matches the fleet's rule.

## Deliberate boundaries

- `consolidator` is out of this repo (2026-10-19; moved 2026-10-21): its job is the Tandem saddlebag, so it lives with that protocol. It now lives in the tandem repo's `agents/`, next to `reviewer` and `retro` — the three passes that run on Tandem, in the project that owns the board and the bikeshed they act on. Tandem's ADR 0026 records the decision; this repo keeps `black`, `blue` and `terse`.
- `black` and `blue` are one prompt, two models — a prompt edit lands identically in both, and the pair isolates the model's effect.
- `main` is protected server-side: PR required, force pushes and deletions refused, zero approvals, linear history off. Squash and rebase merges are still permitted by the server — the merge-commit rule is this repo's convention, not a server rule. A fresh clone gets GitHub's rule and nothing else.
