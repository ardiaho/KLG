# KLG — project guide

SAP ABAP/RAP project for KLG. You talk only to the orchestrator (this session). It picks the right
amount of process for each request, dispatches the agents in `.claude/agents/`, and reports back.
Setting up the SAP connection? See `BOOTSTRAP.md`. Adding a RICEF? See `NEW_WORKSTREAM.md`.

## SAP system
**KSD** (`ksd.sap.klgsys.com`).
- Client **100** = dev. MCP server `zabap-mcp`, env `zabap.env`.
- Client **300** = testing (SIT). MCP server `zabap-mcp-300`, env `zabap-300.env`.
- Repository objects (classes, CDS, tables) are shared across clients, so write and activate through
  `zabap-mcp` (100). Use `zabap-mcp-300` to read test data and check results in 300.
- Transport **<TRANSPORT>**. Package **<PACKAGE>**.

## How the orchestrator works
**1. Pick a lane in one line, then go.** No ceremony, no menu of options.

| Lane | When | What happens |
|---|---|---|
| **Quick** | Question, read/check, one-object fix, no behaviour change | Orchestrator or `dev`/`debug` does it directly. No plan, no TDD, no approval. Report in a few lines. |
| **Standard** | New or changed behaviour, several objects | `architect` plan → you approve once → `dev` (+ `qa` for UI). |
| **Big** | New RICEF/workstream | Standard, plus a workstream folder (`NEW_WORKSTREAM.md`) and `HANDOFF.md`. |

If unsure between two lanes, take the lighter one and say so. A changed requirement mid-work goes
back to `architect` for that change only.

**2. One approval.** The architect plan names the system, client, package and transport that will be
written. Your approval covers exactly those writes. Ask again only for anything outside the plan, deletes,
or a new transport.

**3. TDD is optional. Ask, don't assume.** Small fixes, checks and one-object changes get no TDD and no
question. For Standard/Big work the orchestrator asks one line, either after you approve the plan or once
the build is done, and suggests the timing: "TDD needed? (no / now / after build)". **After build** is the
default suggestion: a TDD is long, and writing it from the finished objects avoids rework when the design
shifts. Suggest **now** (written in parallel with `dev`) only when the design must be agreed before
building, such as an integration contract or a client sign-off. If the build finishes with the question
still unasked, ask then. Only on a yes does `tech-doc` write it. Same for the interface spec: only when
asked. Never skip the question for Standard/Big work. On a yes the TDD is part of the task: it is created
(or updated) and the task is not done until it is approved. On "no" note `TDD: no` in the queue row.
**Every time a TDD is created or modified, `tdd-reviewer` runs over it, independently, before you see it.**
That includes updates after a changed requirement or a `dev` deviation, and any direct edit to its
`values.json` or docx. On NEEDS REVISION `tech-doc` fixes it and the reviewer checks again; you get it only
after APPROVED. No TDD change goes to you unreviewed.

**4. Task queue.** Every request or correction is added to `queue.md` before work starts (one row, your
words). Nothing is cleared or dropped unless you say so; a correction edits its row. Statuses:
`queued` → `running` → `done` | `blocked` | `dropped`. Quick lane items go straight to Done. Mid-task
messages are queued with one line ("queued as Q-012") and work continues. Show the queue when asked.

**5. Parallel by default.** Independent pieces run as parallel agents. Read-only work always runs in
parallel. Two writers never touch the same file or object. `tech-doc` can run next to `dev` when they
touch different files.

**6. Lean.** Do the simplest thing that meets the request. No extras, hardening, options or
future-proofing unless asked or the spec requires it. One line for a real risk, no building for it. Small
choices are decided and stated in one line; ask only when a choice changes business behaviour or data.

**7. Errors.** `debug` finds the cause and hands a fix proposal to `dev`. If the same failure repeats
once, stop and report. VPN/DNS/timeout errors are reported, not retried blindly.

**8. Reporting.** Short: done, how it was verified, not done/not checked, the one decision needed.

**9. Learning, only when there is something to learn.** Agents end their report with a `Lessons` line.
If it is not `none`, or you corrected something, the orchestrator logs it in the queue notes and
dispatches `agent-builder` (smallest change, old file saved to `memory/backups/`, log in
`memory/lessons.md`). No lesson, no step. `workflow-reviewer` runs only on request or when the same
correction shows up twice.

## Agents (`.claude/agents/`)
| Agent | Job |
|---|---|
| `architect` | Research and plan, names what will be written (read-only) |
| `dev` | Builds the approved plan, writes and runs tests, applies fixes |
| `debug` | Diagnoses dumps, exceptions, failing tests (read-only) |
| `qa` | Drives the built UI in a browser, read-only |
| `tech-doc` | TDD / interface spec / HANDOFF, only when asked |
| `tdd-reviewer` | Independent readability check of every TDD, before you see it (read-only) |
| `prompt-writer` | Dispatch prompt for long or unclear briefs only |
| `git-flow` | Only on "git it" / "git and clean" |
| `agent-builder` | Edits agents and this file, at the learning step |
| `workflow-reviewer` | Proposes workflow improvements |

**Dispatch format** (orchestrator writes it, five fields): Goal / Context (verified facts and their source,
system, client, package, transport, agents running) / Task / Constraints (write scope, quoted approval) /
Return (findings, objects touched, read-back result, tests run, open items, `Lessons` line). Agents can
message each other with `SendMessage`; only the orchestrator talks to you and quotes approvals.

## Git
- **"git it"** = branch (if on `main`) → stage → commit → push → open a PR → confirm clean tree. Never
  commit straight to `main`; no auto-merge unless told.
- **"git and clean"** = "git it", then merge the PR → sync `main` → delete the merged branch → clean tree.
- Archive a session when its work is done, not after every push.

## Naming and docs
- Naming and RAP patterns: sibling `../sap-abap-knowledge` (`naming-conventions.md`). KLG overrides go
  here: <!-- e.g. "DDIC prefix Y not Z" -->
- Code changes: follow `../sap-abap-knowledge/klg-code-standards.md`. Header and `MOD###` modification tag on every
  change to existing code, comment out old code instead of deleting it, extended check and ATC before transport.
- Interface specs: always from `../doc-generator/interface-spec/`, driven from a JSON spec, never a
  hand-built docx.
- TDD: build from KLG's own approved template if one exists (sibling repo `../<client>-tdd`). None yet.
  Do not use `doc-generator/tdd/` (it is another client's branded template).

## Not in this repo — recreate per machine
- `zabap.env`, `zabap-300.env`: SAP credentials (gitignored). `.mcp.json`: local paths to `zabap-mcp`.
- Siblings: `../sap-abap-knowledge`, `../doc-generator`.
- `~/.claude` auto-memory does not travel; this file plus each workstream's `HANDOFF.md` is the project memory.

## Workstreams
<!-- One bullet per folder, pointing at its HANDOFF.md. -->
None yet.
