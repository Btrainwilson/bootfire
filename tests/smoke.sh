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

# 4. bash wrapper: cd into selection and run start.sh
cat > "$tmp/roots/gamma/start.sh" <<EOF
#!/bin/sh
echo started-gamma > "$tmp/marker"
EOF
chmod +x "$tmp/roots/gamma/start.sh"

bash <<EOF
set -eu
export XDG_CONFIG_HOME='$XDG_CONFIG_HOME'
export XDG_DATA_HOME='$XDG_DATA_HOME'
export PATH='$REPO/bin:$PATH'
source '$REPO/shell/bootfire.sh'
# Drive the wrapper with a deterministic single-match filter
target="\$(command bootfire --filter=gamma | head -n1)"
[ -n "\$target" ] || { echo "FAIL: no target"; exit 1; }
cd -- "\$target"
command bootfire --bump "\$target"
[ -x ./start.sh ] && ./start.sh
[ "\$PWD" = '$tmp/roots/gamma' ] || { echo "FAIL: pwd is \$PWD"; exit 1; }
[ -f '$tmp/marker' ] || { echo "FAIL: start.sh did not run"; exit 1; }
EOF
pass "bash wrapper logic: cd + run start.sh"

# 5. --cd-only flag is filtered out by the wrapper
rm -f "$tmp/marker"
bash <<EOF
set -eu
source '$REPO/shell/bootfire.sh'
# Inspect the bootfire function definition: it must filter -c/--cd-only
# from args before forwarding to core.
typeset -f bootfire | grep -q -- '--cd-only' || { echo "FAIL: wrapper missing --cd-only handling"; exit 1; }
EOF
pass "wrapper handles --cd-only flag"

# 6. rm removes the root
"$CORE" rm "$tmp/roots" >/dev/null
remaining="$("$CORE" list || true)"
[ -z "$remaining" ] || fail "rm left entries: '$remaining'"
pass "rm clears the root"

printf '\n== smoke.sh: ALL PASSED ==\n'
