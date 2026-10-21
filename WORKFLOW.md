# Workflow

The fleet works in tandem with **Tandem**: the board (`tandem-cli todo …`) is the queue, the bikeshed (`~/.tandem/bikeshed/`) is the memory, and the agents below and the human are the actors. This file is the map of that: who does what, at which gate, and what each handoff passes. The ticket model, its gates, and the board skill live in the Tandem repo; this file names the fleet's actors against them.

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

1. **Capture** — any agent, any time. Every session files its session ticket at start (`Session — <project> · <session-id>`) with a brief — what the session is for and what done looks like — files a `note capture` at each non-obvious decision or gotcha, and closes the ticket at the end with the outcome appended below the brief. The session ticket is work, not a log entry: a board pass refines it and moves it like any other ticket (Tandem ADR 0024). Empty stdin clears a description, so never close a ticket with an empty body — when there is no outcome to record, close it with `todo complete`.
2. **Triage** — the dispatcher pass (`/board`, any primary agent with the `tandem-board` skill). `backlog` → `refined` by grilling; `refined` with no open question and no human-only decision → `ready`; human-only → escalated (`refined`, `assignee human`). One pass, one capture. A session ticket whose session has ended is stale work and joins this queue: the session id in its title settles liveness — `opencode api session.list` shows each session's `outcome` and `time.updated`. A session updated seconds ago is running; a finished one carries an `outcome` of `succeeded`, `failed` or `interrupted`. Neither signal is exact alone — `null` proves nothing, and a resumed session keeps the outcome it had — so read both. A ticket whose session is live belongs to that session and is left alone; a quiet session is not a dead one, so the board's "a claim is not a stall" rule governs the borderline.
3. **Dispatch** — the dispatcher claims a `ready` ticket (`in-progress` + `assignee`) and hands the builder **the ticket id and description only**. The builder orients itself (`AGENTS.md`, the bikeshed, `todo list`), works in a branch or worktree, verifies, opens the PR, files captures, and ends with one `work` capture.
4. **Review** — the `reviewer` subagent reads the ticket, the diff, the checks, the repo's rules, and the PR's `## Merge Danger` claim. Two-way door + low blast radius → merge commit, then complete the ticket. One-way or high → escalate to the human with `file:line` risks. Cannot merge this pass → `blocked`, stays with its author.
5. **Retro** — the `retro` subagent over a named session; each finding that clears the bar becomes a `backlog` ticket in the project's lane. Zero tickets is valid. The trigger is not yet defined — see Gaps.
6. **Consolidate** — the `consolidator` subagent, on the human's request only (`/consolidate`): folds the project's raw captures into the curated notes and archives the consumed. Never automatic, never at session close.

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
- **Orientation** for a new session — the bikeshed `Index` → the project's curated note → `todo list`, or the `/handoff` block for a paste-ready cut.

## Gaps (2026-10-21)

Each is filed as a `backlog` ticket — in the `fleet` lane for this repo's own gaps, in the `Tandem` lane for the four that live there; this section is the summary.

1. **The builder prompts carry no PR contract.** `reviewer.md` states the whole contract (the `## Merge Danger` claim, the merge-commit rule, the evidence) and `black`/`blue` state none of it. A missing claim forces the reviewer to guess the class, and every builder re-derives the contract from the README. Cost: the handoff depends on the builder having happened to read. Next move: put the contract in the shared builder prompt — or decide deliberately that the project's `AGENTS.md` delivers it, so the fleet prompts stay host-agnostic.
2. **The fleet repo has no `AGENTS.md`; the protocol arrives through host glue.** Fleet sessions run the memory and session-ticket rules because `~/.config/opencode/opencode.json` points `instructions` at `~/projects/tandem/AGENTS.md` — another project's file, invisible to a fresh clone and to any other host. Cost: the fleet declares nothing about itself; on a host without that entry, fleet sessions run without the protocol. Next move: an `AGENTS.md` in this repo carrying the fleet's own rules.
3. **Completion ownership is stated twice, differently.** `reviewer.md` (the two-way action) completes the ticket it merges; the board skill's dispatch step has the root verify the evidence, then complete. Cost: a double completion, or a ticket left `in-progress` at the handoff. Next move: one rule in both documents — the actor holding the evidence completes (as stated in Completion above).
4. **The host command bindings are untracked.** `/board`, `/handoff` and `/consolidate` are real files in `~/.config/opencode/commands/`, not symlinks into this repo, so the workflow's entry points do not survive a fresh clone or a host move — and the README's "Not in this repo" names only the consolidator. Cost: the map of the fleet is incomplete exactly where the fleet is entered. Next move: track the three files here and symlink them (as `terse` is), or list them under "Not in this repo" with the reason.
5. **The retro trigger is undefined.** `retro` is dispatchable, but nothing names when a retro runs — session end, a long session, or the human's call. Cost: it never runs, or it runs twice over the same session. Next move: a rule in this file and the board skill.
6. **The roster of record omits the built-ins and the bindings.** The README's Agents table lists only the four fleet-defined agents, while the board already carries `general` as an assignee and the commands above are real entry points. Cost: a fresh session cannot map an `assignee: general` ticket or a `/board` run to anything in the repo. Next move: extend the table or point it at the Roster above.
7. **The live skills on this Mac are a stale untracked copy of the tandem `main` checkout.** `~/.config/opencode/opencode.json` points `skills` at `~/projects/tandem/skills` — the `main` checkout, behind `dev`, with `skills/tandem-board/` untracked there and different from `dev`. The live `AGENTS.md` and the live board skill also disagreed with each other about the old `Session —` skip. Cost: the rules this file maps are not the rules the machine runs, and a merged change is not a live one. Filed in the `Tandem` lane as `DDC3811D`. Next move: get the live skills onto a tracked branch, and decide whether they track `dev` or the release line.
8. **The CLI clears a description on empty stdin.** `todo set --description -` with an empty pipe normalises the body to nothing and wipes the description, exit 0, no warning — confirmed on a throwaway home. The session-ticket protocol depends on that description, so this is the one CLI behaviour that can destroy what it preserves. Filed in the `Tandem` lane as `5621FB91`. Next move: make an empty `--description -` a domain failure, as `todo comment add` already does for an empty body.
9. **The installed build is behind the source on `in-review`.** The tandem source has carried the sixth `Status` since `562b69a` (ADR 0017) — one `Status` enum serves the CLI, the store and the GUI, and `Status.parse` takes all six. But the installed `tandem-cli` and `Tandem.app` are 0.14.0, tagged two hours earlier, which has five: `todo set --status in-review` is refused, and a `todos.json` holding `"status": "in-review"` reads back as `backlog` through it. The board skill names `in-review` as a gate, so an agent following the documentation reaches for a status the running stack will not take. Filed in the `Tandem` lane as `ED140046`. Next move: release and install the build carrying the sixth value, in ADR 0017's own order — release, install, then let any writer store it — and until then never hand-write `in-review` into `todos.json`, because the installed app would show it in the wrong column.
10. **`tandem/dev` requires one approving review, which one identity cannot give.** The reviewer and the human share a GitHub account, so GitHub refuses an author approving their own PR and the count is unsatisfiable. Every agent-driven merge into `dev` therefore waits for the human with `--admin` — which the reviewer is forbidden to use. The fleet's own `main` requires **zero** approvals for exactly this reason, so the two repos differ on the same decision. Filed in the `Tandem` lane as `7FFD7CD7`. Next move: decide whether `dev` matches the fleet's rule.

## Deliberate boundaries

- `consolidator` is out of this repo by decision (2026-10-19): its job is the Tandem saddlebag, so it lives with that protocol.
- `black` and `blue` are one prompt, two models — a prompt edit lands identically in both, and the pair isolates the model's effect.
- `main` is protected server-side: PR required, force pushes and deletions refused, zero approvals, linear history off. Squash and rebase merges are still permitted by the server — the merge-commit rule is this repo's convention, not a server rule. A fresh clone gets GitHub's rule and nothing else.
