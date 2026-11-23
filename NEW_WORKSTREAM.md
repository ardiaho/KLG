# Adding a new RICEFW / task to <CLIENT>

Read this **before** creating a folder or any objects for a new RICEF/RICEFW or task.
It is the checklist Claude follows so every workstream in this repo has the same shape. (This
checklist was generalized from the `Olenex` repo's `rtr-001-payment-advice/` and
`pm-009-rf-scanning/` — real examples of the pattern, not folders that exist in a fresh repo
from this template.)

## 0. Golden rules
- **One folder per workstream, fully self-contained.** *Every* artifact for that RICEFW —
  CDS, behavior, DCL, UI5, print, docs — lives inside its own folder. **Nothing** goes at the
  repo root or into another workstream's folder.
- **Propose names, then wait.** Before generating any object, propose the folder name +
  object naming and **wait for the user to confirm**. Where the spec is silent (message class,
  table/field names, package, valuation handling, etc.) **do not invent values** — mark a `TODO`
  and list them for the user.
- **Any func spec the user sends gets saved to the repo immediately** — whether it's a brand-new
  workstream or an existing one. Do this as a direct action in the same turn it's received; don't
  leave it living only in chat history, and don't wait for a `tech-doc` dispatch to get around to
  it.
  - **If the user sends an actual file** (docx/pdf/etc.), copy that file itself into
    `<workstream>/` — the real file is what's wanted, not a summary of it. A markdown extract
    (`FS-extract.md`, matching `otc-019-goods-issue/FS-extract.md`'s pattern) is a *useful
    addition* for searchability, never a substitute for keeping the actual file.
  - **If the user pastes spec text directly into chat** (no file), then `FS-extract.md` is the
    right place for it, since there's no original file to copy.
  - If a real file arrives later for something already captured as a chat-pasted extract, copy
    the file in and note in `FS-extract.md` that it now supersedes/complements the file.
- **Real credentials never get committed.** `.mcp/` holds only the `.example`; the real env
  file sits at the repo root and is gitignored (see the global MCP rules).

## 1. Folder name
Lowercase kebab-case: **`<ricef-id>-<short-slug>/`**.
Examples: `rtr-001-payment-advice/`, `pm-009-rf-scanning/`.

## 2. Subfolders (create only the ones the workstream needs)
| Subfolder | Holds |
|---|---|
| `cds/` | Interface + projection CDS views, metadata extensions |
| `behavior/` | Behavior definitions + implementation classes |
| `dcl/` | Access controls (DCL) |
| `ui5/` | Freestyle SAPUI5 app (manifest, views, controllers) |
| `print/` | Print program + form (Adobe/SmartForm/SAPscript) |
| `tdd/` | `values.json` + `repeat.json` — the inputs that fill the TDD template |
| *(ad hoc)* | `forms/`, `enhancements/`, etc. as the object mix demands |

## 3. Required file — `HANDOFF.md`
Every workstream folder starts with a `HANDOFF.md`. Copy the skeleton and follow the section
structure in **[`handoff-template.md`](https://github.com/ardiaho/sap-abap-knowledge/blob/main/handoff-template.md)**
(separate repo, clone as `../sap-abap-knowledge`; mirrors the existing two workstreams). Keep
dates absolute (`2026-07-15`), not "today".

## 3b. Deliverable — the TDD
If `<CLIENT>` has its own approved TDD template (real letterhead/logos, fixed section order),
set it up as its own sibling repo — same shape as
[ardiaho/doc-generator](https://github.com/ardiaho/doc-generator)'s `tdd/` folder (the real,
tagged, one-tag-per-fillable-spot pattern), cloned as `../<client>-tdd` — and build from that,
never from scratch or a generic docx generator. **`ardiaho/doc-generator`'s `tdd/` folder itself
is Olenex's own WILMAR-branded template — don't point a different client at it.** (Its
`interface-spec/` folder is client-agnostic though — clone `../doc-generator` for that regardless
of whether `<CLIENT>` has its own TDD template.) No approved TDD template yet for `<CLIENT>`?
Drop this section until one exists.

Either way: re-read the SAP system (`GetTransport` on the TR, then the objects it lists) before
writing — `HANDOFF.md` drifts and the TR is the source of truth for scope. Keep the fill inputs
in `<workstream>/tdd/` so the document can be regenerated.

## 4. Naming conventions (SAP objects)
Full tables + examples are the single source of truth in
**[`naming-conventions.md`](https://github.com/ardiaho/sap-abap-knowledge/blob/main/naming-conventions.md)**
(separate repo, clone as `../sap-abap-knowledge`). In brief:
DDIC `Z<mod><type>_` (2-letter type infix), CDS/RAP `Z<type>_<mod><proc>`, classic
`Z<mod><proc>_<name>`, UI5 lowercase namespace; `ZZDE_`/`ZZDO_` for cross-module reuse only.
For unmanaged RAP + BAPI commit sequencing see
**[`rap-patterns.md`](https://github.com/ardiaho/sap-abap-knowledge/blob/main/rap-patterns.md)**.

## 5. Package & transport
- Confirm the **SAP system/client** and the **package** with the user. Prefer a
  **module parent package** (e.g. `ZFI_RTR`, `ZPM`) with a per-workstream child
  (`ZPM_<business-process>`) — name the child after the **business process**, not the technical
  channel (e.g. not "RF").
- Create the transport via `zabap-mcp` only after the user approves the package + TR text.

## 6. Memory + index updates (do these when a workstream is created)
1. Add a memory file under the Claude memory dir:
   `.claude/projects/…/memory/<ricef-id>-<slug>.md` (`type: project`), summarizing what it is,
   scope, confirmed conventions, and a pointer to the folder's `HANDOFF.md`.
2. Add a one-line pointer to that memory in `MEMORY.md`.
3. Add the workstream to the **Workstreams** list in `CLAUDE.md`.

## 7. Scaffolding order (once names are confirmed)
For a RAP + UI5 build, generate incrementally and pause for review after each stage:
a. CDS interface + projection views, behavior definitions/implementations
b. Unmanaged action handlers wrapping BAPIs (hardest-logic process first) — show the
   commit/rollback sequence explicitly and comment why each call sits where it does
c. DCL access controls + authority checks
d. UI5 app: manifest, routing, menu, then one view/controller per process
e. Classic print program + form

Do **not** scaffold Fiori Elements annotations for screen rendering when the frontend is
freestyle UI5. CDS annotations are fine for labels, value helps, and defaults only.
