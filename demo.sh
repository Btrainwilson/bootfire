#!/usr/bin/env bash
# bootfire/demo.sh — scripted walkthrough for asciinema / screencap.
# Runs in an isolated XDG environment, won't touch your real config.
# Sources the bootfire wrapper so the picker round-trip is real (cd
# and start.sh sourcing both happen inside this script).
#
# Tweak pacing with env vars:
#   TYPE_DELAY=0.04   # seconds per char while "typing"
#   BEAT=0.8          # pause between sections

set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLAYGROUND="$(mktemp -d)"
trap 'rm -rf "$PLAYGROUND"' EXIT

export XDG_CONFIG_HOME="$PLAYGROUND/.config"
export XDG_DATA_HOME="$PLAYGROUND/.data"
export PATH="$ROOT/bin:$PATH"

# Make `bootfire` a function in this script — same hook the user's
# shell rc would install. Now `bootfire` actually cd's and sources
# start.sh inside the demo, instead of just printing a path.
. "$ROOT/shell/bootfire.sh"

TYPE_DELAY="${TYPE_DELAY:-0.035}"
BEAT="${BEAT:-0.8}"
SECTION_PAUSE="${SECTION_PAUSE:-1.2}"

B=$(printf '\033[1m')
D=$(printf '\033[2m')
ORANGE=$(printf '\033[38;5;208m')
RUST=$(printf '\033[38;5;130m')
GOLD=$(printf '\033[38;5;178m')
R=$(printf '\033[0m')

beat()    { sleep "$BEAT"; }
section() { sleep "$SECTION_PAUSE"; }

title() { printf '\n%s%s%s\n\n'      "$B$RUST" "$1" "$R"; }
say()   { printf '%s%s%s\n'          "$D"      "$1" "$R"; }
note()  { printf '%s  # %s%s\n'      "$D"      "$1" "$R"; }

type_cmd() {
    printf '%s❯%s ' "$GOLD" "$R"
    s="$1"
    while [ -n "$s" ]; do
        printf '%s' "${s%"${s#?}"}"
        s="${s#?}"
        sleep "$TYPE_DELAY"
    done
    printf '\n'
    sleep 0.35
}

# fake projects
mkdir -p "$PLAYGROUND/projects/api-server"
mkdir -p "$PLAYGROUND/projects/web-app"
mkdir -p "$PLAYGROUND/projects/scratch-notes"
cat > "$PLAYGROUND/projects/web-app/start.sh" <<'EOF'
echo "  → web-app: dev server up on :3000 (demo)"
export DEMO_ACTIVE_PROJECT=web-app
EOF
chmod +x "$PLAYGROUND/projects/web-app/start.sh"

clear
printf '%s\n' "$ORANGE"
cat <<'BANNER'
.______     ______     ______   .___________. _______  __  .______       _______ 
|   _  \   /  __  \   /  __  \  |           ||   ____||  | |   _  \     |   ____|
|  |_)  | |  |  |  | |  |  |  | `---|  |----`|  |__   |  | |  |_)  |    |  |__   
|   _  <  |  |  |  | |  |  |  |     |  |     |   __|  |  | |      /     |   __|  
|  |_)  | |  `--'  | |  `--'  |     |  |     |  |     |  | |  |\  \----.|  |____ 
|______/   \______/   \______/      |__|     |__|     |__| | _| `._____||_______|

MIT

BANNER
printf '%s\n' "$R"
say "(playground: $PLAYGROUND — cleaned up on exit)"
section

title "1. register a project root"
note "tildes are expanded; one root or many"
type_cmd "bootfire add $PLAYGROUND/projects"
bootfire add "$PLAYGROUND/projects"
beat

title "2. confirm what's tracked"
type_cmd "bootfire list"
bootfire list
section

title "3. preview the candidates fzf will show"
note "BOOTFIRE_PRINT_CANDIDATES=1 dumps them without invoking fzf"
note "(we use 'command' here to bypass the sourced shell wrapper)"
type_cmd "BOOTFIRE_PRINT_CANDIDATES=1 command bootfire"
BOOTFIRE_PRINT_CANDIDATES=1 command bootfire
section

title "4. pick a project (live)"
note "fzf opens — type a few letters, hit enter to confirm (Esc to bail)"
note "the wrapper will cd into the pick and source its start.sh"
sleep 1.0
type_cmd "bootfire"
bootfire || true
beat

title "5. resulting shell state"
note "cd persisted, env var from start.sh persisted"
type_cmd "pwd"
pwd
type_cmd "echo \$DEMO_ACTIVE_PROJECT"
printf '%s\n' "${DEMO_ACTIVE_PROJECT:-(unset — pick was a project without start.sh)}"
section

title "that's the whole tool."
say "fd walks · fzf picks · the wrapper cds and sources start.sh."
say "no daemon, no shell hooks."
printf '\n'
