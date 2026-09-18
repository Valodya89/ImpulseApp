#!/usr/bin/env python3
"""
Load the app translations (translations.json) into the Impulse locale service
(locale.impulsepower.ru) - the same service and the same calls as the Translation
tab of the Impulse admin site (admin.impulsepower.ru).

What the admin site does, read from its shipped bundle (main.*.js):
  - A key is a "message": POST {locale}/api/message
        {"id": "<MODULE>_<name>", "description": "...", "module": "<module>"}
    after checking it does not exist with
        POST {locale}/api/message/search?page=0&size=1
        {"criteria": [{"fieldName": "id", "fieldValue": id, "searchOperation": "EQUALS"}]}
  - Each language of a key is a "translation": POST {locale}/api/translation
        {"key": id, "language": "en", "module": "<module>", "value": "..."}
  - Auth is "Authorization: Bearer <admin access token>".

This script only ADDS. It reads the public dictionaries first
(GET {locale}/<module>/translations/<lang>) and sends only the (key, language)
pairs that are missing there, so an existing translation is never overwritten.
A 409 / duplicate answer counts as "already there", so re-running is safe.

Usage:
    ./push-translations.py                          # dry run, no token needed
    ./push-translations.py --languages en             # dry run, English only
    export IMPULSE_ADMIN_TOKEN="<access token from your admin session>"
    ./push-translations.py --apply --limit 3        # try three keys first
    ./push-translations.py --apply                  # everything missing

Get the token yourself from a logged-in admin.impulsepower.ru session (browser dev
tools -> Network -> any admin request -> Authorization header, without "Bearer ").
Never commit it or paste it anywhere shared.

The locale service rebuilds a module's cache before saving a new row, so a value
can be missing from the public dictionary right after it is written. If the
verification pass reports gaps, wait and run the dry run again.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

BASE_URL = "https://locale.impulsepower.ru"
LANGUAGES = ["en", "ru"]
HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "translations.json")


def http(method, url, token=None, body=None, timeout=30):
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode("utf-8") if body is not None else None
    request = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", "replace")
            return response.status, parse(raw)
    except urllib.error.HTTPError as error:
        return error.code, parse(error.read().decode("utf-8", "replace"))
    except Exception as error:  # noqa: BLE001 - report, never abort the batch
        return 0, {"message": str(error)}


def parse(raw):
    try:
        return json.loads(raw)
    except ValueError:
        return {"message": raw[:160]}


def envelope_status(http_status, payload):
    """The locale service wraps results in {statusCode, message, content}."""
    if isinstance(payload, dict) and isinstance(payload.get("statusCode"), int):
        return payload["statusCode"]
    return http_status


def is_duplicate(status, payload):
    message = str((payload or {}).get("message", "")).lower()
    return status == 409 or "duplicate" in message or "already exist" in message


def live_dictionary(module, language):
    status, payload = http("GET", f"{BASE_URL}/{module}/translations/{language}")
    content = payload.get("content") if isinstance(payload, dict) else None
    if status != 200 or not isinstance(content, dict):
        raise RuntimeError(f"could not read {module}/{language}: {status}")
    return content


def load_live(modules, languages):
    return {(m, l): live_dictionary(m, l) for m in modules for l in languages}


def missing_rows(data, live, languages):
    rows = []
    for key, entry in sorted(data.items()):
        module = entry["module"]
        for language in languages:
            value = (entry.get(language) or "").strip()
            if not value:
                continue
            current = live[(module, language)].get(key)
            if isinstance(current, str) and current.strip():
                continue
            rows.append((key, module, language, entry[language]))
    return rows


def message_exists(token, key):
    status, payload = http(
        "POST",
        f"{BASE_URL}/api/message/search?page=0&size=1",
        token,
        {"criteria": [{"fieldName": "id", "fieldValue": key, "searchOperation": "EQUALS"}]},
    )
    code = envelope_status(status, payload)
    if code in (401, 403):
        raise PermissionError(f"{code}: the token was rejected")
    content = (payload or {}).get("content") or {}
    items = content.get("content") if isinstance(content, dict) else None
    return bool(items)


def create_message(token, key, module, description):
    status, payload = http(
        "POST", f"{BASE_URL}/api/message", token,
        {"id": key, "description": description, "module": module},
    )
    code = envelope_status(status, payload)
    if code in (401, 403):
        raise PermissionError(f"{code}: the token was rejected")
    if 200 <= code < 300:
        return "created", ""
    if is_duplicate(code, payload):
        return "exists", ""
    return "failed", f"{code} {(payload or {}).get('message', '')}"


def create_translation(token, key, module, language, value):
    status, payload = http(
        "POST", f"{BASE_URL}/api/translation", token,
        {"key": key, "language": language, "module": module, "value": value},
    )
    code = envelope_status(status, payload)
    if code in (401, 403):
        raise PermissionError(f"{code}: the token was rejected")
    if 200 <= code < 300:
        return "created", ""
    if is_duplicate(code, payload):
        return "exists", ""
    return "failed", f"{code} {(payload or {}).get('message', '')}"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="write for real (needs IMPULSE_ADMIN_TOKEN)")
    parser.add_argument("--languages", default=",".join(LANGUAGES), help="comma list, default: en,ru")
    parser.add_argument("--keys", default="", help="comma list of keys to limit to")
    parser.add_argument("--limit", type=int, default=0, help="only the first N keys that have gaps")
    args = parser.parse_args()

    languages = [l.strip() for l in args.languages.split(",") if l.strip()]
    unknown = [l for l in languages if l not in LANGUAGES]
    if unknown:
        print(f"unknown languages: {unknown}", file=sys.stderr)
        return 2

    data = json.load(open(DATA, encoding="utf-8"))
    if args.keys:
        wanted = {k.strip() for k in args.keys.split(",") if k.strip()}
        data = {k: v for k, v in data.items() if k in wanted}

    bad = [k for k, v in data.items() if not k.startswith(v["module"].upper() + "_")]
    if bad:
        # The admin site builds ids as <MODULE>_<name>; anything else would not
        # match what the app asks for.
        print(f"skipping keys whose prefix does not match their module: {bad}", file=sys.stderr)
        data = {k: v for k, v in data.items() if k not in bad}

    modules = sorted({v["module"] for v in data.values()})
    print(f"reading live dictionaries: modules={modules} languages={languages}")
    live = load_live(modules, languages)

    rows = missing_rows(data, live, languages)
    keys_with_gaps = sorted({r[0] for r in rows})
    if args.limit:
        keys_with_gaps = keys_with_gaps[: args.limit]
        rows = [r for r in rows if r[0] in set(keys_with_gaps)]

    print(f"\n{len(data)} keys in the file, {len(keys_with_gaps)} with gaps, {len(rows)} translations to add")
    per = {}
    for _, module, language, _ in rows:
        per[(module, language)] = per.get((module, language), 0) + 1
    for (module, language), count in sorted(per.items()):
        print(f"  {module:<11} {language}  {count}")

    if not rows:
        print("\nNothing to do - every translation is already live.")
        return 0

    if not args.apply:
        print("\nDRY RUN - nothing was written. Sample:")
        for key, module, language, value in rows[:8]:
            print(f"  {module}/{language}  {key} = {value}")
        print(f"  ... and {max(len(rows) - 8, 0)} more. Re-run with --apply to write.")
        return 0

    token = os.environ.get("IMPULSE_ADMIN_TOKEN", "").strip()
    if token.lower().startswith("bearer "):
        token = token[7:].strip()
    if not token:
        print("IMPULSE_ADMIN_TOKEN is not set.", file=sys.stderr)
        return 1

    tally = {"message created": 0, "message existed": 0, "created": 0, "exists": 0, "failed": 0}
    failures = []
    try:
        for key in keys_with_gaps:
            entry = data[key]
            module = entry["module"]
            if message_exists(token, key):
                tally["message existed"] += 1
            else:
                outcome, detail = create_message(token, key, module, entry.get("en") or key)
                if outcome == "failed":
                    tally["failed"] += 1
                    failures.append(f"message {key}: {detail}")
                    continue
                tally["message created" if outcome == "created" else "message existed"] += 1

            for row_key, row_module, language, value in rows:
                if row_key != key:
                    continue
                outcome, detail = create_translation(token, key, row_module, language, value)
                tally[outcome] += 1
                if outcome == "failed":
                    failures.append(f"{language} {key}: {detail}")
                time.sleep(0.05)
    except PermissionError as error:
        print(f"\nSTOPPED - {error}. Get a fresh token from admin.impulsepower.ru and re-run; "
              "anything already written is skipped next time.", file=sys.stderr)
        return 1

    print("\n" + " | ".join(f"{k} {v}" for k, v in tally.items()))
    for line in failures:
        print(f"  FAILED  {line}", file=sys.stderr)

    print("\nverifying against the public dictionaries...")
    live = load_live(modules, languages)
    still = [r for r in missing_rows(data, live, languages) if r[0] in set(keys_with_gaps)]
    if still:
        print(f"{len(still)} still missing publicly (the cache may lag - re-run the dry run in a minute):")
        for key, module, language, _ in still[:20]:
            print(f"  {module}/{language}  {key}")
    else:
        print("all written translations are live.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
