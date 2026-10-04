#!/usr/bin/env bash
# Claude Code SessionStart hook for repositories that take their rules from
# the mimo-knowledge MCP server. The rules in CLAUDE.md and the hook scripts
# are a local copy with a version number (.claude/mimo-instructions.version).
# This asks the server for the current version and, only when it differs,
# tells Claude to refresh the copy before doing anything else. When the copy
# is current, or the server cannot be reached, it prints nothing.
#
# Served by the mimo-knowledge MCP tools get_mobile_repo_setup /
# get_backend_repo_setup; install as .claude/hooks/check-mimo-instructions.sh.
# Needs only bash, curl and grep. No token is sent: the version is public.

dir="${CLAUDE_PROJECT_DIR:-.}"
local_version="$(tr -d '[:space:]' < "$dir/.claude/mimo-instructions.version" 2>/dev/null)"
base="${MIMO_MCP_BASE_URL:-https://mcp.mimobike.com}"
server_version="$(curl -fsS -m 4 "$base/instructions/version" 2>/dev/null \
  | grep -o '"version" *: *[0-9][0-9]*' | grep -o '[0-9][0-9]*$')"

# Server unreachable or answer not understood: keep working with the local copy.
[ -z "$server_version" ] && exit 0
[ "$server_version" = "$local_version" ] && exit 0

setup_call="${MIMO_SETUP_CALL:-get_mobile_repo_setup or get_backend_repo_setup}"
cat <<EOF
MIMO INSTRUCTIONS ARE OUTDATED in this repository: local version ${local_version:-none}, server version ${server_version}.
Before any other work in this session:
  1. Call the mimo-knowledge MCP tool ${setup_call}.
  2. Follow the returned steps: replace the registry section in CLAUDE.md, overwrite the hook
     files, write .claude/mimo-instructions.version, then commit exactly those files and push.
  3. Read the new section, tell the user in one line that the instructions were updated from
     ${local_version:-none} to ${server_version}, then continue with the user's task under the new rules.
EOF
exit 0
