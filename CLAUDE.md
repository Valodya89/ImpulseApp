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

## Mobile feature registry (mimo-knowledge MCP)

This repository is **IMPULSE iOS** (`app=impulse`, `platform=ios`). It is
one of six sibling apps: Impulse, Mimo and EVUP, each on Android and iOS. They
share one code lineage, so a feature built here usually has to be built in the
others too. The `mimo-knowledge` MCP server keeps ONE record per feature for
all six apps: what it is, how to implement it, which apps it applies to and
which apps already have it. It is authenticated with the developer's own
`MIMO_MCP_TOKEN`; every call is recorded under that developer's name.

### Keep these instructions current — version 13

This section and the hook scripts are a local copy of rules that live on the
mimo-knowledge MCP server. The copy has **version 13**, also stored
in `.claude/mimo-instructions.version`. Before you change anything in a
session, make sure the copy is current:

1. Call `get_instructions_version` (the session-start check does the same and
   prints a notice when the copy is outdated; `pending_mobile_features` and
   `list_mobile_apps` also return `instructionsVersion`).
2. If the server's version is 13, continue.
3. If it differs, update first: call `get_mobile_repo_setup` with
   `app=impulse`, `platform=ios`, follow its steps (replace this
   section, overwrite the hook files, write the version file, then commit
   exactly those instruction files and push), read the new section, tell the
   user in one line that the instructions went from 13 to the new
   version, and only then continue with the task.

Never edit this section by hand: a change belongs on the server.

### Before you start a task

1. Call `pending_mobile_features` with `app=impulse`, `platform=ios`.
2. Tell the user in one short list what other apps or platforms already have
   that is still missing here. Do not implement anything unasked.
3. If the task is one of those pending features, call `get_mobile_feature`
   with its key and build it from the `implementationGuide`,
   `acceptanceCriteria` and the other targets' notes, instead of designing
   from scratch.

### When asked to implement the pending or missing features

Every pending feature must end in exactly ONE of these four outcomes. Never
skip one silently, and never stop after the first few.

1. **Built here.** You implemented it in this repository. Call
   `implement_mobile_feature` with the files you changed and notes.
2. **No change needed here.** You checked the code and this app already
   behaves as the feature describes, or the bug a `fix` describes does not
   occur in this app or on this platform. That is still DONE from this
   app's side: call `implement_mobile_feature` with `notes` that start with
   `No change needed:` followed by the reason, and `filesChanged` listing the
   files you checked as evidence. Do not leave it pending: a feature that
   stays pending here looks like missing work to everyone else.
3. **Does not apply to this app at all.** The app does not have the service
   (for example scooter rental in EVUP). Call `update_mobile_feature` with
   `applicableApps` without this app. If it is a toolchain fix that can only
   exist on the other platform, set `applicablePlatforms` to that platform.
4. **Cannot be done now.** It needs something that is not available (a
   backend endpoint that is not live, a design decision, credentials) or is
   too large for this session. Leave it pending and report it with the
   reason. This is the only case in which a feature may stay pending.

How to work through them:

- Call `pending_mobile_features` and page with `offset` until you have every
  key. Write the full list down as a checklist before changing anything.
- Take them one at a time: `get_mobile_feature`, look at this repository's
  code, decide the outcome, do it, record it. Finish and record one feature
  before starting the next, so an interrupted session loses nothing.
- Outcome 2 needs evidence. "Probably fine" is not a check: name the class or
  function that already does it, or explain why the bug cannot happen here.
- When you are done, call `pending_mobile_features` again. What is still
  listed must be exactly your outcome-4 list. If anything else is still
  pending, you missed it: go back and handle it.
- Report a table: key, outcome (built / no change needed / not applicable /
  blocked), and one line of reason.

### Before every commit

Do this for every commit that changes behaviour, UI, navigation, networking,
strings, configuration, permissions or build setup. Skip it only for pure
formatting, comments, tests or CI edits.

**Step 1 — Find the feature.** One feature has exactly one record. Before
creating anything, look for it: `pending_mobile_features` for this app, or
`list_mobile_features` with `scope=all` and a `query` or `component`.

**Step 2a — It exists: add this app to it.** Call `implement_mobile_feature`
with its `key`, `app=impulse`, `platform=ios`, `branch`, `version`,
`filesChanged` and `notes` (what differs here from the guide, what was not
ported, pitfalls) and `localizationKeys` with any translation key you had to
add that the feature did not list yet. If you learned something every
platform needs, also call `update_mobile_feature` to improve the guide.

**Step 2b — It is new: create it once.** Call `create_mobile_feature` with:

- `title`: one line, e.g. "Wallet: pending top-ups with a badge"
- `component`: reuse a name from `list_mobile_apps` (wallet, profile, scooter,
  charger, notifications, websocket, map, auth, home, ...)
- `type`: `feature`, `fix` or `change`
- `description`: what the user sees and gets, business rules, edge cases
- `implementationGuide`: everything another developer's agent needs to build
  it on another platform without seeing this code: flow and states, backend
  endpoints and DTOs (use `search_docs` / `read_doc` and cite the document
  path, never guess), socket events, localisation keys, remote-config flags,
  analytics events, permissions, pitfalls
- `acceptanceCriteria`: a checklist that proves an implementation is equal
- `localizationKeys`: every translation key the feature shows, exactly as
  stored in the locale service (for example `MOBILE_wallet_pending_badge`),
  including the keys you added for it. The other apps use this list instead
  of inventing their own keys.
- `applicableApps`: decide explicitly. Default is all three. Narrow it only
  when an app does not have the service at all, for example scooter or bike
  rental is `[mimo]`, EV charging is `[mimo, evup]`, Impulse branding is
  `[impulse]`. Auth, wallet, profile, push, maps, localisation and error
  handling are global. An applicable app always means both its platforms.
- `applicablePlatforms`: leave empty. Set `[ios]` only for a
  toolchain-specific fix that cannot exist on the other platform
- `implementedApp=impulse`, `implementedPlatform=ios`, `branch`,
  `version`, `filesChanged`, `notes`

If the answer contains `similar` features, nothing was created. Read them:
when one is the same feature, go to Step 2a with its key. Only when yours is
really different, call again with `confirmNew=true`.

**Step 3 — Commit** with the returned `commitReference` as the last line:

```
fix(wallet): show pending top-ups with a badge

Mobile-Feature: Wallet: pending top-ups with a badge : wallet-pending-top-ups-with-a-badge
```

The commit hook asks for that line on commits Claude makes. Use
`Mobile-Feature: none` only for the excluded cases above.

### Crashes and errors the app reported

The apps send crashes and errors to the backend, and the same MCP server
gives access to them, always for one app and platform. For this repository
that is `app=impulse`, `platform=ios`.

- **To see what is broken:** `mobile_error_summary`. Each bug appears once
  with how often it happened, on how many devices and app versions, and when.
  Crashes come first. A group with `resolvedBefore` was fixed earlier and has
  come back: read that note first.
- **To investigate one bug:** `get_mobile_error` with the group's
  `latestReportId` for the stack trace and the context the app attached
  (breadcrumbs, thread, network, build type); `list_mobile_errors` with the
  `fingerprint` for the other occurrences when one report is not enough.
- **To fix it:** find the cause in this repository, fix it, and verify. If
  the fix changes behaviour, register it like any other change
  (`type=fix`), which also tells the other apps to check the same bug.
- **After the fix is committed:** `delete_mobile_errors` with the bug's
  `fingerprint` and a `resolution` saying what fixed it (commit, feature
  key) and `fixedInVersion`. The note is kept, so the bug coming back shows
  as a regression.
- **Delete only** what you fixed and verified, or what is provably obsolete
  (a test build, a version nobody runs any more), and say which it is in the
  `resolution`. Never delete reports to tidy up, never delete reports you
  have not read, and when you are unsure whether a fix covers a group, leave
  the group and tell me.
- If `delete_mobile_errors` answers that the reports of this app are
  read-only on the server, that is expected for some apps: do not retry, keep
  the fingerprint and what fixed it in your report instead.
- Users on an older app version can still send an error you already fixed.
  Check `appVersions` before deciding a fix did not work.
- `deviceId` and `userId` identify a real customer. Never put them in a
  commit message, a feature record, a translation or the chat.

When asked to "fix the crashes" or "process the errors", work through the
summary from the top: one bug at a time, fix, commit, delete its reports,
then the next. At the end report a table: fingerprint, what it was, what you
did (fixed and deleted / obsolete and deleted / left, with the reason).

### Texts and translations

The apps' texts come from the locale service and are managed through the same
MCP server. Mimo and EVUP share one locale service; Impulse has its own with
its own keys and languages. So pass `app=impulse` to every translation tool
(`list_translation_modules`, `search_translations`, `get_translation`,
`missing_translations`, `add_translation`, `reload_translation_cache`);
without it the tools answer for the shared Mimo/EVUP service. Before using a
text key: `search_translations` for the text or the key, and reuse an existing
key when the text already exists. A new text: `add_translation` with the
module, a key that follows the module's prefix (`MOBILE_`, `EV_CHARGER_` …), a
description of where it is shown, and the value in every language the module
lists (`en` is required; the others in the same call). Keep placeholders
identical in all languages. Never overwrite an existing value without asking
me.

Every feature carries its translation keys in `localizationKeys`:

- **When you build a new feature,** pass every key it shows in
  `localizationKeys` of `create_mobile_feature`.
- **When you port a feature,** `get_mobile_feature` lists its keys with the
  module, the languages that have a value and the ones still missing, per
  locale service when the feature spans Impulse and Mimo/EVUP
  (`localeService`). Use exactly those keys. Do not create a second key for a
  text that already has one. If a key exists only in the other locale service,
  add it to yours with `add_translation` (same key, same texts). If this
  platform needs a text the feature does not list, add the key with
  `add_translation` and pass it in `localizationKeys` of
  `implement_mobile_feature`, which adds it to the feature.
- A key reported as "not found in the locale service" was named but never
  added: add it with `add_translation`, or correct the list with
  `update_mobile_feature`.

### Keeping the registry right

- A feature that turns out not to apply to an app: `update_mobile_feature`
  with the corrected `applicableApps`. A feature that now applies to an app it
  did not before: add the app the same way; a completed feature then returns
  to the pending list of that app.
- An implementation recorded by mistake: `unimplement_mobile_feature`.
- When every applicable app on both platforms has implemented a feature, the
  server moves it to the completed collection by itself.
- Never put secrets, tokens or customer data in a description, guide or note.
