#!/bin/sh
# Unit test for bootfire's frecency tracking and ranking. Drives the
# core via BOOTFIRE_PRINT_CANDIDATES=1 to read ranked output without fzf.

set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$REPO/bin/bootfire"
chmod +x "$CORE"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_CONFIG_HOME="$tmp/config"
export XDG_DATA_HOME="$tmp/data"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

mkdir -p "$tmp/roots/alpha" "$tmp/roots/beta" "$tmp/roots/gamma"

pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; exit 1; }

command -v fd >/dev/null 2>&1 || { echo "SKIP: fd not installed"; exit 0; }

printf '== frecency.sh ==\n'

# 1. Bump creates an entry with count=1
"$CORE" --bump "$tmp/roots/alpha"
frec="$XDG_DATA_HOME/bootfire/frecency"
[ -f "$frec" ] || fail "frecency file not created"
count="$(awk -F'\t' -v p="$tmp/roots/alpha" '$1 == p { print $2 }' "$frec")"
[ "$count" = "1" ] || fail "expected count=1, got '$count'"
pass "first bump creates count=1"

# 2. Bump increments the same entry
"$CORE" --bump "$tmp/roots/alpha"
"$CORE" --bump "$tmp/roots/alpha"
count="$(awk -F'\t' -v p="$tmp/roots/alpha" '$1 == p { print $2 }' "$frec")"
[ "$count" = "3" ] || fail "expected count=3, got '$count'"
pass "subsequent bumps increment"

# 3. Bumps to different paths track independently
"$CORE" --bump "$tmp/roots/beta"
acount="$(awk -F'\t' -v p="$tmp/roots/alpha" '$1 == p { print $2 }' "$frec")"
bcount="$(awk -F'\t' -v p="$tmp/roots/beta"  '$1 == p { print $2 }' "$frec")"
[ "$acount" = "3" ] && [ "$bcount" = "1" ] || fail "independent counts: a=$acount b=$bcount"
pass "independent path tracking"

# 4. Ranking: bump gamma the most, expect it first
"$CORE" add "$tmp/roots"
for _ in 1 2 3 4 5; do "$CORE" --bump "$tmp/roots/gamma"; done

ranked="$(BOOTFIRE_PRINT_CANDIDATES=1 "$CORE")"
first="$(printf '%s\n' "$ranked" | head -n1)"
case "$first" in
    "$tmp/roots/gamma") pass "highest-frecency dir ranks first" ;;
    *) fail "expected gamma first, got '$first'" ;;
esac

printf '\n== frecency.sh: ALL PASSED ==\n'
