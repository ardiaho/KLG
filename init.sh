#!/usr/bin/env bash
# Bootstrap a new client repo from this template.
# Run from inside the freshly-created client repo (after cloning it locally):
#   ./init.sh "Acme Corp"
set -euo pipefail

CLIENT_NAME="${1:-}"
if [ -z "$CLIENT_NAME" ]; then
  echo "Usage: ./init.sh \"<Client Name>\""
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$REPO_ROOT")"

echo "== 1/3: cloning sap-abap-knowledge and doc-generator as siblings =="
if [ -d "$PARENT_DIR/sap-abap-knowledge" ]; then
  echo "  sap-abap-knowledge already present at $PARENT_DIR/sap-abap-knowledge — skipping"
else
  git clone https://github.com/ardiaho/sap-abap-knowledge.git "$PARENT_DIR/sap-abap-knowledge"
fi
if [ -d "$PARENT_DIR/doc-generator" ]; then
  echo "  doc-generator already present at $PARENT_DIR/doc-generator — skipping"
else
  git clone https://github.com/ardiaho/doc-generator.git "$PARENT_DIR/doc-generator"
fi

echo "== 2/3: creating CLAUDE.md from CLAUDE.template.md =="
if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
  echo "  CLAUDE.md already exists — not overwriting. Delete it first if you want a fresh copy."
else
  sed "s/<CLIENT>/$CLIENT_NAME/g" "$REPO_ROOT/CLAUDE.template.md" > "$REPO_ROOT/CLAUDE.md"
  echo "  wrote CLAUDE.md — still fill in <SYSTEM>, <CLIENT-NO>, <TRANSPORT>, <PACKAGE>, and the"
  echo "  Workstreams section by hand; those aren't guessable."
fi

echo "== 3/3: writing .mcp.json and zabap.env =="
ZABAP_DIR="$PARENT_DIR/mcp/zabap-mcp"
if [ ! -d "$ZABAP_DIR" ]; then
  echo "  zabap-mcp not found at $ZABAP_DIR — cloning and installing"
  mkdir -p "$PARENT_DIR/mcp"
  git clone https://github.com/ardiaho/zabap-mcp.git "$ZABAP_DIR"
  (cd "$ZABAP_DIR" && npm install)
fi
# node on Windows needs C:/... paths, not /c/... (pwd -W only exists in Git Bash)
ABS_ROOT="$(cd "$REPO_ROOT" && { pwd -W 2>/dev/null || pwd; })"
ABS_PARENT="$(dirname "$ABS_ROOT")"
ZABAP_BIN="$ABS_PARENT/mcp/zabap-mcp/node_modules/@mcp-abap-adt/core/bin/mcp-abap-adt.js"
if [ ! -f "$REPO_ROOT/.mcp.json" ]; then
  sed -e "s#<ZABAP_MCP_BIN>#$ZABAP_BIN#" -e "s#<CLIENT_REPO_ABS_PATH>#$ABS_ROOT#" \
    "$REPO_ROOT/.mcp/mcp.json.example" > "$REPO_ROOT/.mcp.json"
  echo "  wrote .mcp.json (zabap-mcp convention, incl. --tls-min-v1.0 --tls-max-v1.2)"
fi
if [ ! -f "$REPO_ROOT/zabap.env" ]; then
  sed "s/<CLIENT>/$CLIENT_NAME/g" "$REPO_ROOT/.mcp/zabap.env.example" > "$REPO_ROOT/zabap.env"
  echo "  wrote zabap.env — fill in host, client, credentials"
fi

echo "== reminders =="
cat <<EOF
Still manual (can't be scripted — needs real values):
  - Fill remaining <PLACEHOLDER>s in CLAUDE.md (SAP system/client/transport/package).
  - Fill real SAP host/client/credentials in ./zabap.env (generated above).
  - .mcp.json was generated (zabap-mcp convention, incl. TLS flags). Connect the VPN, then
    restart Claude Code so it loads the zabap-mcp server.
  - doc-generator/interface-spec/ works as-is (client-agnostic) once cloned above.
  - doc-generator/tdd/ is Olenex's own WILMAR-branded TDD template — do NOT use it for this
    client. If this client has its own approved TDD template (real letterhead, fixed layout),
    set it up as its own sibling repo (same shape as doc-generator's tdd/ folder, e.g.
    ../<client>-tdd) and reference it from CLAUDE.md's "Writing a TDD" section. No template yet?
    Drop that section for now.
  - git add -A && git commit -m "Initial client repo setup" (this repo, not the sibling repos).
EOF
