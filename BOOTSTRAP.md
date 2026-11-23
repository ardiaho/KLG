# BOOTSTRAP.md — instructions for AI agents

Read this when the user says "init project", "new client", "new connection", or opens an empty
or freshly-copied client folder. **Do not ask what stack — this template IS the answer.** Do not
scaffold a generic app (UI5, CAP, npm init, etc.).

## What this repo is
Template for a new SAP ABAP/RAP client repo: Claude agent pipeline (`.claude/agents/`),
`CLAUDE.template.md`, and `init.sh` which wires everything else up.

## Do this, in order
1. Confirm the client name (e.g. `W21`). If the user already gave one, use it.
2. Work from the client folder (a copy of this template, `.git` removed). If it is empty, copy
   this template into `SAP/<Client>` first. Look in sibling folders under `SAP/` before asking
   the user anything: `ZABAP_MCP-CLIENT-TEMPLATE`, `mcp/zabap-mcp`, `sap-abap-knowledge`, `doc-generator`.
3. Run `bash init.sh "<Client>"`. It clones missing siblings (`sap-abap-knowledge`,
   `doc-generator`, `mcp/zabap-mcp` + `npm install`), writes `CLAUDE.md`, writes `.mcp.json`
   (from `.mcp/mcp.json.example`, absolute paths, zabap-mcp TLS convention), and writes
   `zabap.env` at the repo root (gitignored).
4. Fill non-secret values the user gave you into `zabap.env`: `SAP_URL` (scheme + host + port
   only, no `/sap/bc/adt...` path), `SAP_CLIENT`, `SAP_MASTER_SYSTEM`, and the matching
   `<SYSTEM>`/`<CLIENT-NO>` in `CLAUDE.md`.
5. Report what is still manual (below). Do not commit unless asked.

## Never
- Never type, guess, or echo `SAP_USERNAME` / `SAP_PASSWORD`. The user fills those in.
- Never commit `zabap.env` or `.mcp.json` (both gitignored).
- Never use `doc-generator/tdd/` for a new client (Olenex-branded).
- Never remove the `--tls-min-v1.0 --tls-max-v1.2` flags from `.mcp.json` without being asked;
  old SAP systems hang without them. The `"env": { "TLS_REJECT_UNAUTHORIZED": "0" }` block in `.mcp.json` is part of the template (self-signed on-prem certs; same as Olenex). Do not add more TLS relaxations than the template has.

## Still manual after init.sh
- SAP username/password in `zabap.env`; VPN connected.
- `CLAUDE.md` placeholders: dev/test/prod, transport, package, workstreams.
- Restart Claude Code so it loads `.mcp.json` (`zabap-mcp` tools appear). A
  `CONNECT_TIMEOUT` means: check VPN/host reachability, then the TLS flags and `zabap.env`.

## Conventions
- Client-agnostic naming/RAP patterns: sibling `../sap-abap-knowledge`.
- Interface specs: `../doc-generator/interface-spec/`.
- New workstream: follow `NEW_WORKSTREAM.md`. New or changed requirement goes to the
  `architect` agent first (see `CLAUDE.md`).
