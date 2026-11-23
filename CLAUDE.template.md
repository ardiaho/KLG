# <CLIENT> — project guide

> **Template.** Copy this file to `CLAUDE.md` (or let `init.sh` do it), replace every
> `<PLACEHOLDER>`, and delete the lines/sections that don't apply. Claude Code auto-loads
> `CLAUDE.md` (not this file) on connect. Keep it lean; details live in the linked `HANDOFF.md`
> files. See `README.md` for the repo layout and `NEW_WORKSTREAM.md` for how to add a workstream.
> Setting up this repo or its SAP connection? Follow `BOOTSTRAP.md`.

Auto-loaded by Claude Code on connect. Keep it lean; details live in the linked files.

## Workflow convention
- **"git it"** = branch (if on `main`) → stage → commit → `git push` → **open a PR** → confirm the
  working tree is clean. Branch per change (never commit straight to `main`); **do not auto-merge**
  unless told. Stops at an open PR.
- **"git and clean"** = do the full **"git it"**, then **merge the PR into `main`** → sync `main` →
  **delete the merged branch** (local + remote) → confirm the working tree is clean.
- **Archive a session when its work is done**, not after every push.

## Agent pipeline
Stack-agnostic — same 5 agents work for SAP ABAP/RAP backend, Fiori/UI5 frontend, or general web
dev. User talks **only to this session** — it's the orchestrator; dispatch subagents via the
Agent tool and report back, don't tell the user to invoke one themselves. Custom subagents live
in **`.claude/agents/`** (came with this template, portable as-is):
- **`architect`** — the gate. Every new/changed requirement goes here first, no exceptions.
  Nothing else starts until the user approves its plan.
- **`tech-doc`** — TDD, interface spec, HANDOFF/NEW_WORKSTREAM-equivalent updates, from the
  project's own templates. Dispatch once architect's plan is approved.
- **`dev`** — builds/updates objects, then writes and runs tests. Dispatch once the plan (and
  TDD/interface spec, if applicable) exists. Never hand it a requirement directly.
- **`debug`** — root-causes dumps/exceptions/failing tests, hands back to `dev`.
- **`git-flow`** — the "git it" / "git and clean" ritual, standalone, any time.

Chain: `architect` → user review → `tech-doc` → `dev` → (`debug` on error, loops back) → `dev`.
**Any new or changed requirement re-enters at `architect`** — never mid-chain.

## Naming conventions & dev patterns
Client-agnostic SAP ABAP naming/RAP-pattern reference lives in the separate
**[ardiaho/sap-abap-knowledge](https://github.com/ardiaho/sap-abap-knowledge)** repo — clone it
as a sibling (`../sap-abap-knowledge`). Override per-client naming here if `<CLIENT>`'s standard
differs from the default in `naming-conventions.md`:
<!-- - <override, e.g. "DDIC prefix Y not Z">  -->

## Writing a TDD
<!-- If <CLIENT> has its own approved TDD template (real letterhead/logos, fixed section order),
     that belongs in its OWN sibling repo — same shape as ardiaho/doc-generator's tdd/ folder,
     cloned as ../<client>-tdd — never build one from scratch or from a generic docx generator.
     No approved template yet? Drop this section until one exists. -->

## Writing an interface spec (contract for a middleware/integration team)
**Always** build it from **`doc-generator/interface-spec/`** (clone as `../doc-generator`) —
never hand-build a docx. Drive the generator from a JSON spec. This part is client-agnostic, so
the shared `doc-generator` repo works as-is — no per-client fork needed for this doc type.

## Adding a new RICEFW / task
Read **`NEW_WORKSTREAM.md`** — the checklist for folder layout and the memory/index updates
to make.

## SAP system
**<SYSTEM>**, client **<CLIENT-NO>** (<dev/test/prod>). Transport **<TRANSPORT>**.
Package **<PACKAGE>**.

## Not in this repo — recreate per machine
- `zabap.env` at the repo root — SAP credentials for the `zabap-mcp` MCP server (gitignored).
- `.mcp.json` — machine-specific paths to the shared `zabap-mcp` server binary.
- **`../sap-abap-knowledge`**, **`../doc-generator`**, and, if applicable, **`../<client>-tdd`**
  (a client-branded TDD template) — clone as siblings of this repo.
- Claude's `~/.claude` auto-memory does not travel with the repo; treat this file +
  the per-workstream `HANDOFF.md` as the portable project memory.

## Workstreams
<!-- One bullet per folder. Point at each folder's HANDOFF.md; mark which is active work. -->
- **`<ricef-id>-<slug>/`** — RICEF **<RICEF-ID>**, <one-line description>. **<Active work? / status>.**
  Start by reading **`<ricef-id>-<slug>/HANDOFF.md`** — current status, decisions, remaining steps.

## <RICEF-ID> quick status (see HANDOFF.md for full detail)
<!-- Optional: a few lines of the most-active workstream's state so it's visible on connect.
     Drop this section if there's no active work worth surfacing at the top level. -->
- <key status line>
- <key decision / blocker>
