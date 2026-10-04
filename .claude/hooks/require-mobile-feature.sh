#!/usr/bin/env bash
# Claude Code PreToolUse hook (matcher: Bash) for the Mimo / EVUP / Impulse
# mobile repositories. When Claude runs `git commit`, the commit message must
# reference the feature it belongs to in the mimo-knowledge feature registry:
#
#     Mobile-Feature: <feature title> : <feature-key>
#
# or `Mobile-Feature: none` for work nobody has to repeat in another app
# (formatting, comments, tests, CI). Commits made by hand are not affected.
#
# Served by the mimo-knowledge MCP tool get_mobile_repo_setup; install as
# .claude/hooks/require-mobile-feature.sh. Needs only bash + grep.

input="$(cat)"

# Only Bash tool calls that run git commit.
printf '%s' "$input" | grep -q '"tool_name" *: *"Bash"' || exit 0
printf '%s' "$input" | grep -Eq '(^|[;&|[:space:]("])git[[:space:]]+([^;&|]*[[:space:]])?commit([[:space:]]|\\|$)' || exit 0

# Amends, merges, fixups and reverts keep or generate their own message.
printf '%s' "$input" | grep -Eq -- '--amend|--fixup|--squash|--no-edit|git[[:space:]]+(merge|revert|cherry-pick)' && exit 0

# Referenced (or consciously skipped) -> allow.
printf '%s' "$input" | grep -Eq 'Mobile-Feature:[[:space:]]*[A-Za-z0-9]' && exit 0

app="${MIMO_MOBILE_APP:-<app>}"
platform="${MIMO_MOBILE_PLATFORM:-<platform>}"
cat >&2 <<EOF
Commit blocked: register this work in the mimo-knowledge feature registry first.

  1. Does the feature already exist? Check pending_mobile_features (app=${app},
     platform=${platform}) or list_mobile_features with a query.
       - exists  -> implement_mobile_feature(key, app=${app}, platform=${platform}, ...)
       - new     -> create_mobile_feature(..., implementedApp=${app}, implementedPlatform=${platform})
         (if it answers with 'similar' features, use the matching one instead)
  2. Add the returned commitReference line to the commit message, e.g.
        Mobile-Feature: Wallet: pending top-ups with a badge : wallet-pending-top-ups-with-a-badge
  If nothing has to be repeated in another app or platform (formatting, comments,
  tests, CI), use:  Mobile-Feature: none
EOF
exit 2
