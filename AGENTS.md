# AGENTS.md

The rules a session in this repo runs under: the memory it records, the ticket it files, and where the workflow is written down. The map is [`WORKFLOW.md`](WORKFLOW.md) — this file is the pointer to it, plus the rules a fleet session needs on its own.

## Memory

This repo's memory is the Tandem **bikeshed** (`~/.tandem/bikeshed/`), reached through the `tandem-memory` skill. Before you read or edit repo files, and as you work:

- **Orient first.** Load the `tandem-memory` skill, then read the bikeshed's `Index.md`, this repo's curated note (the `fleet` folder under the bikeshed), and `tandem-cli todo list`. Do this before touching repo files.
- **Record captures as you work.** File one with `tandem-cli note capture --kind <decision|gotcha|fact|work|thread> --project fleet` at each non-obvious decision or gotcha.
- **The `work` note is the floor.** A session that ends without one has recorded nothing, however the session went.
- **Never edit a curated note.** `Index.md` and the curated notes have one writer: the consolidation pass. Consolidation is deliberate, never automatic — at session close the captures simply keep. When the human asks, hand the saddlebag to a fresh consolidation agent.
- **Applies to sub-agents too.** A child session receives this section like the root does, so a brief need not restate it — give the child its task, nothing more.

The full protocol is in the `tandem-memory` skill.

## Sessions

Every session records itself as a ticket, so the board shows what is running and what each session did. The ticket is work, not a log entry: a board pass refines it and moves it like any other ticket.

- **File it at session start**, with a brief — what this session is for and what done looks like:

  ```
  tandem-cli todo add --title "Session — fleet · <session-id>" --status in-progress [--assignee <agent>]
  tandem-cli todo set --id <ticket-id> --description -
  ```

  `<session-id>` is `$OPENCODE_SESSION_ID` (a short token when the host exports none), and `<agent>` is your agent's name when the session tells you — omit the flag when it does not.

- **One ticket per session.** If `tandem-cli todo list --filter all --text "Session — <project> · <session-id>"` already shows one, file nothing.

- **Close it at session end**, before your final reply: read the description, append the outcome below the brief under a heading of your own, and write it back. The description is written once and appended to, never overwritten.

- **Empty stdin clears the description.** `--description -` takes the body on stdin, and an empty pipe writes an empty body, which the store normalises to nothing — the description is gone, exit 0, no warning. So a command that pipes nothing erases the brief. Never run `--description -` without a body, and check what you are piping. When there is no outcome to record, close the ticket with `tandem-cli todo complete --id <ticket-id>`, which leaves the description alone.

- **A session that resumes reopens its ticket:** `tandem-cli todo set --id <ticket-id> --status in-progress`.

- **Children file their own.** A sub-agent session is a session; it closes its ticket when it finishes.

Session tickets live in the default area, so they never depend on a lane that may not exist.

## Workflow

[`WORKFLOW.md`](WORKFLOW.md) is the map of the fleet: the roster, the six passes — capture → triage → dispatch → review → retro → consolidate — the handoff contract at each boundary, the completion rule, and the gaps where the fleet does not yet fully run on Tandem. Read it before a pass, and change it there when a rule moves — it holds them.

This repo owns the two builders (`black`, `blue`) and the `terse` style. The passes that run on Tandem — `refine`, `reviewer`, `retro`, `consolidator` — live in the Tandem repo, which owns the board and the bikeshed they act on.

## The shared protocol

The memory and session rules above are Tandem's, not this repo's invention: the Tandem repo's [`AGENTS.md`](https://github.com/gianniacquisto/tandem/blob/dev/AGENTS.md) is the protocol the two repos share, and this file holds the part a fleet session needs. Read it there for the rest — the store's own hazards, the board skill's rules — and change it there when it changes.

Nothing in a repo may name a path on one machine. This file names the bikeshed, the CLI and this repo's own files; a clone of this repo, anywhere, plus the app and the CLI, is the whole setup.
