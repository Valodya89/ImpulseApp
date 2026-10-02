# Impuls

## Mimo backend documentation

Authoritative backend documentation is served by the mimo-knowledge MCP
server. Before writing or changing any integration with Mimo backend services
(endpoints, request/response fields, enums, error codes, auth, payments,
wallet, rentals, EV charging), call its search_docs / read_doc tools and
follow what the documentation says. Never guess endpoint paths, field names,
enum values or error codes — if the docs do not answer, say so instead of
inventing. Every answer from this server carries the source repository, file
path and commit SHA — prefer the newest commit and cite the source.

## Mobile change sync (mimo-knowledge MCP) — mandatory before every commit

This repository is app = `impulse`, platform = `ios`, repository =
`Valodya89/ImpulseApp`. It is one of six sibling code bases: Impulse, Mimo
and EVUP, each on Android and iOS. They share one code lineage, so most
changes made here must be repeated elsewhere. The mimo-knowledge MCP server
(authenticated with the developer's own MIMO_MCP_TOKEN) keeps the change log
that makes this possible. Every tool call is recorded under the developer's
name.

If the server's tools did not load in the session (401 at startup: `.mcp.json`
carries the literal `${MIMO_MCP_TOKEN}` placeholder and the desktop app does not
source `~/.zshrc`, where the token is exported), call the same tools through
`.claude/mimo_mcp.sh` from Bash instead of skipping the workflow.

### Before you start a task

1. Call pending_mobile_changes with app=impulse, platform=ios.
2. Tell the user, in one short list, what other platforms or apps already did
   that is still missing here. Do not implement them unasked.
3. If the current task is one of those pending changes, call
   get_mobile_change and follow its prompt instead of designing from
   scratch. Remember its id: you will pass it as appliedFrom when you publish.

### Before every commit — publish first, then commit

Do this for every commit that changes behaviour, UI, navigation, networking,
strings, configuration, permissions or build setup. Skip it only for pure
formatting, comments, tests or CI edits.

Step 1 — Summarise the change in your own words, from the user's point of
view: what the user sees or gets, what rules apply, what the edge cases are.

Step 2 — Decide the scope. Answer these questions explicitly and put the
answers in the summary:

- *Which apps does this apply to?* Default: all three (impulse, mimo,
  evup). Narrow it only when the change depends on something the other apps
  do not have, for example an EV-charging-only screen (evup only), a
  bike/scooter rental flow (mimo only), or Impulse branding (impulse
  only). Shared things such as auth, wallet, profile, push routing, maps,
  localisation and error handling are global.
- *Which platforms does this apply to?* Default: both. Narrow to one when the
  change is toolchain-specific (Gradle, Xcode project, ProGuard, Info.plist,
  a platform-only SDK bug).
- *Is this an original change or a port?* If you implemented a change that
  was pending from another platform/app, it is a port.

Step 3 — Publish with one publish_mobile_change call per logical change:

- app=impulse, platform=ios
- title: one line, e.g. "Wallet page: show pending top-ups with a badge"
- summary: the Step 1 summary plus the Step 2 scope reasoning
- prompt: instructions that let another developer's agent reproduce the
  change without seeing your code: expected behaviour, rules, backend
  endpoints and DTOs used (cite the mimo-knowledge doc path), edge cases,
  localisation keys added, remote-config keys, analytics events
- area: one of wallet, auth, home, charging, rental, map, profile, push,
  localisation, build, other
- compatibleApps / compatiblePlatforms: from Step 2 (omit when global)
- filesChanged, repository=Valodya89/ImpulseApp, branch
- appliedFrom=<source id> when it is a port

Step 4 — Commit with the returned trailer as the last line of the commit
message:

    fix(wallet): show pending top-ups with a badge

    Mobile-Change: 66f1a2b3c4d5e6f7a8b9c0d1

The commit hook refuses commits without a Mobile-Change: line. Use
Mobile-Change: none only for the excluded cases above (formatting, comments,
tests, CI), never to save time.

### When a pending change does not belong here

Call mark_mobile_change_applied with status=not_applicable and a note
saying why (for example "Impulse iOS has no bike rental module"). Never leave
a change pending just because it was inconvenient.

### Never

- Publish secrets, tokens or customer data in a summary or prompt.
- Publish twice for one logical change; amend by publishing a follow-up
  change instead.
- Guess backend endpoints in the prompt: use search_docs / read_doc and
  cite the document.
