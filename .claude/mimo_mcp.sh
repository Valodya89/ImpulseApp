#!/bin/zsh
# Fallback transport for the mimo-knowledge MCP server when its tools do not
# load in a Claude session (401: MIMO_MCP_TOKEN is exported in ~/.zshrc but the
# desktop app does not source it). Reads the token from ~/.zshrc, never prints it.
#
# usage: .claude/mimo_mcp.sh '<json-rpc request>'   -> prints the JSON-RPC response body
#   .claude/mimo_mcp.sh '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
#   .claude/mimo_mcp.sh '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"pending_mobile_changes","arguments":{"app":"mimo","platform":"ios","limit":30}}}'
# The result text of a tools/call is in .result.content[0].text (itself JSON).
set -e
TOKEN=$(grep -E 'export MIMO_MCP_TOKEN=' ~/.zshrc | head -1 | sed -E 's/.*MIMO_MCP_TOKEN=//; s/^["'"'"']//; s/["'"'"']$//')
[ -z "$TOKEN" ] && { echo "no token in ~/.zshrc" >&2; exit 1; }
URL=https://mcp.mimobike.com/mcp
H=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")
HDRS=$(mktemp)
curl -s -D "$HDRS" -o /dev/null "${H[@]}" "$URL" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}'
SID=$(grep -i '^mcp-session-id:' "$HDRS" | awk '{print $2}' | tr -d '\r')
[ -z "$SID" ] && { echo "no session id" >&2; cat "$HDRS" >&2; exit 1; }
curl -s -o /dev/null "${H[@]}" -H "Mcp-Session-Id: $SID" "$URL" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'
curl -s "${H[@]}" -H "Mcp-Session-Id: $SID" "$URL" -d "$1" | python3 -c '
import sys,re
b=sys.stdin.read()
if b.lstrip().startswith("{"): print(b)
else: print("\n".join(re.sub(r"^data:\s?","",l) for l in b.splitlines() if l.startswith("data:")))'
