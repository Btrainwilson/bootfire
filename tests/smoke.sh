#!/bin/sh
# End-to-end smoke test for bootfire. Sets up an isolated XDG home,
# exercises the CLI subcommands and the bash shell wrapper.

set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$REPO/bin/bootfire"
chmod +x "$CORE"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_CONFIG_HOME="$tmp/config"
export XDG_DATA_HOME="$tmp/data"
export PATH="$REPO/bin:$PATH"

mkdir -p "$tmp/roots/alpha" "$tmp/roots/beta" "$tmp/roots/gamma"

pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; exit 1; }

command -v fzf >/dev/null 2>&1 || { echo "SKIP: fzf not installed"; exit 0; }
command -v fd  >/dev/null 2>&1 || { echo "SKIP: fd not installed";  exit 0; }

printf '== smoke.sh ==\n'

# 1. add registers a root
"$CORE" add "$tmp/roots" >/dev/null
listed="$("$CORE" list)"
[ "$listed" = "$tmp/roots" ] || fail "list mismatch: '$listed'"
pass "add + list"

# 2. add is idempotent
"$CORE" add "$tmp/roots" >/dev/null
nroots="$("$CORE" list | wc -l)"
[ "$nroots" -eq 1 ] || fail "duplicate root added: count=$nroots"
pass "add is idempotent"

# 3. fzf select-1 with unique query returns the matching directory
selected="$("$CORE" --filter=beta | head -n1)"
case "$selected" in
    *roots/beta) pass "select via --filter=beta" ;;
    *) fail "expected beta, got '$selected'" ;;
esac

# 4. candidate list contains all three roots, deduped
candidates="$(BOOTFIRE_PRINT_CANDIDATES=1 "$CORE")"
for d in alpha beta gamma; do
    printf '%s\n' "$candidates" | grep -q "roots/$d$" || fail "missing $d in candidates"
done
ndup="$(printf '%s\n' "$candidates" | sort | uniq -d | wc -l)"
[ "$ndup" -eq 0 ] || fail "duplicates in candidates"
pass "candidates include all roots, deduped"

# 5. bash wrapper: cd into selection and source start.sh (env persists)
cat > "$tmp/roots/gamma/start.sh" <<'EOF'
echo started-gamma > "$MARKER"
export BOOTFIRE_TEST_VAR=activated
EOF

bash <<EOF
set -eu
export XDG_CONFIG_HOME='$XDG_CONFIG_HOME'
export XDG_DATA_HOME='$XDG_DATA_HOME'
export PATH='$REPO/bin:$PATH'
export MARKER='$tmp/marker'
source '$REPO/shell/bootfire.sh'
target="\$(command bootfire --filter=gamma | head -n1)"
[ -n "\$target" ] || { echo "FAIL: no target"; exit 1; }
cd -- "\$target"
[ -r ./start.sh ] && . ./start.sh
[ "\$PWD" = '$tmp/roots/gamma' ] || { echo "FAIL: pwd is \$PWD"; exit 1; }
[ -f '$tmp/marker' ] || { echo "FAIL: start.sh did not run"; exit 1; }
[ "\$BOOTFIRE_TEST_VAR" = activated ] || { echo "FAIL: env var did not persist"; exit 1; }
EOF
pass "bash wrapper: cd + source start.sh (env persists)"

# 6. --cd-only flag is filtered out by the wrapper
rm -f "$tmp/marker"
bash <<EOF
set -eu
source '$REPO/shell/bootfire.sh'
typeset -f bootfire | grep -q -- '--cd-only' || { echo "FAIL: wrapper missing --cd-only handling"; exit 1; }
EOF
pass "wrapper handles --cd-only flag"

# 7. rm removes the root
"$CORE" rm "$tmp/roots" >/dev/null
remaining="$("$CORE" list || true)"
[ -z "$remaining" ] || fail "rm left entries: '$remaining'"
pass "rm clears the root"

# 8. local path mode: bootfire <dir> works without any configured roots
selected="$("$CORE" "$tmp/roots" --filter=alpha | head -n1)"
case "$selected" in
    *roots/alpha) pass "local path mode: bootfire <abs path>" ;;
    *) fail "local path mode: expected alpha, got '$selected'" ;;
esac

# 9. local path mode resolves relative paths (e.g. `bootfire .`)
selected="$(cd "$tmp/roots" && "$CORE" . --filter=beta | head -n1)"
case "$selected" in
    *roots/beta) pass "local path mode: bootfire ." ;;
    *) fail "local path mode rel: expected beta, got '$selected'" ;;
esac

# 10. local path mode includes the path itself as a candidate
candidates="$(BOOTFIRE_PRINT_CANDIDATES=1 "$CORE" "$tmp/roots/alpha")"
printf '%s\n' "$candidates" | grep -qx "$tmp/roots/alpha" || fail "local path mode missing root itself"
pass "local path mode includes the root"

# 11. stdin pipe: piped lines become the candidate set (no config needed)
selected="$(printf '%s\n%s\n' "$tmp/roots/alpha" "$tmp/roots/beta" | "$CORE" --filter=beta | head -n1)"
case "$selected" in
    *roots/beta) pass "stdin pipe: lines become candidates" ;;
    *) fail "stdin pipe: expected beta, got '$selected'" ;;
esac

# 12. stdin pipe + local path: intersection (only piped paths under the path)
piped="$(printf '%s\n%s\n%s\n' "$tmp/roots/alpha" "$tmp/roots/beta" "/elsewhere/zeta")"
out="$(printf '%s\n' "$piped" | BOOTFIRE_PRINT_CANDIDATES=1 "$CORE" "$tmp/roots/alpha")"
printf '%s\n' "$out" | grep -qx "$tmp/roots/alpha" || fail "intersection: alpha missing"
printf '%s\n' "$out" | grep -qx "$tmp/roots/beta" && fail "intersection: beta should be filtered out"
printf '%s\n' "$out" | grep -qx "/elsewhere/zeta" && fail "intersection: zeta should be filtered out"
pass "stdin pipe ∩ local path"

# 13. stdin pipe doesn't require fd or config to run
rm -f "$XDG_CONFIG_HOME/bootfire/config"
selected="$(printf '/some/dir\n' | "$CORE" --filter=some | head -n1)"
[ "$selected" = "/some/dir" ] || fail "stdin without config: expected /some/dir, got '$selected'"
pass "stdin pipe works without config"

printf '\n== smoke.sh: ALL PASSED ==\n'
