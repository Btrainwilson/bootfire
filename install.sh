#!/bin/sh
# bootfire installer — for `curl | sh` use.
# For local development installs use `make install` instead.

set -eu

NAME="bootfire"
REPO_URL="${BOOTFIRE_REPO_URL:-https://github.com/btrainwilson/bootfire.git}"
BRANCH="${BOOTFIRE_BRANCH:-main}"
INSTALL_DIR="${BOOTFIRE_INSTALL_DIR:-$HOME/.local/share/$NAME}"
BIN_DIR="${BOOTFIRE_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/$NAME"

say()  { printf '\033[1;34m[%s]\033[0m %s\n' "$NAME" "$*"; }
warn() { printf '\033[1;33m[%s]\033[0m %s\n' "$NAME" "$*" >&2; }
die()  { printf '\033[1;31m[%s]\033[0m %s\n' "$NAME" "$*" >&2; exit 1; }

detect_pm() {
    for pm in apt-get brew pacman dnf apk; do
        command -v "$pm" >/dev/null 2>&1 && { printf '%s\n' "$pm"; return 0; }
    done
    return 1
}

install_pkg() {
    pm="$1"; shift
    case "$pm" in
        apt-get) sudo apt-get update -qq && sudo apt-get install -y "$@" ;;
        brew)    brew install "$@" ;;
        pacman)  sudo pacman -Sy --noconfirm "$@" ;;
        dnf)     sudo dnf install -y "$@" ;;
        apk)     sudo apk add "$@" ;;
        *)       die "unsupported package manager: $pm" ;;
    esac
}

ensure_fd_shim() {
    # Debian/Ubuntu install fd as `fdfind`. Create an `fd` symlink so the
    # rest of bootfire can call `fd` uniformly.
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        mkdir -p "$BIN_DIR"
        ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
        say "linked fdfind -> $BIN_DIR/fd"
    fi
}

ensure_deps() {
    pm="$(detect_pm)" || die "no supported package manager found (need apt-get, brew, pacman, dnf, or apk)"

    if ! command -v fzf >/dev/null 2>&1; then
        say "installing fzf via $pm"
        install_pkg "$pm" fzf
    fi

    if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
        say "installing fd via $pm"
        case "$pm" in
            apt-get) install_pkg apt-get fd-find ;;
            *)       install_pkg "$pm" fd ;;
        esac
    fi

    ensure_fd_shim
}

fetch_repo() {
    command -v git >/dev/null 2>&1 || die "git is required to fetch $NAME"
    if [ -d "$INSTALL_DIR/.git" ]; then
        say "updating $INSTALL_DIR"
        git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH"
        git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH"
    else
        if [ -e "$INSTALL_DIR" ]; then
            backup="$INSTALL_DIR.bak.$(date +%s)"
            warn "$INSTALL_DIR exists but isn't a git checkout — moving to $backup"
            mv "$INSTALL_DIR" "$backup"
        fi
        say "cloning $REPO_URL into $INSTALL_DIR"
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    fi
}

install_files() {
    mkdir -p "$BIN_DIR" "$CONFIG_DIR"
    chmod +x "$INSTALL_DIR/bin/$NAME"
    ln -sf "$INSTALL_DIR/bin/$NAME" "$BIN_DIR/$NAME"
    [ -e "$CONFIG_DIR/config" ] || cp "$INSTALL_DIR/share/default-config" "$CONFIG_DIR/config"
    [ -e "$CONFIG_DIR/ignore" ] || cp "$INSTALL_DIR/share/default-ignore" "$CONFIG_DIR/ignore"
}

SENTINEL_START="# >>> bootfire >>>"
SENTINEL_END="# <<< bootfire <<<"

# Drop a file in fish conf.d (fish auto-sources every *.fish there).
# No rc edits, removable by `rm`.
wire_fish() {
    fish_conf_d="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d"
    mkdir -p "$fish_conf_d"
    target="$fish_conf_d/$NAME.fish"
    printf 'source %s/shell/%s.fish\n' "$INSTALL_DIR" "$NAME" > "$target"
    say "wrote fish conf.d hook: $target"
}

# Replace (not append) a sentinel-marked block in an rc file.
# Idempotent: reinstall rewrites the block instead of stacking copies.
wire_posix_rc() {
    rc="$1"
    line="$2"
    [ -f "$rc" ] || : > "$rc"
    tmp="$(mktemp)"
    awk -v s="$SENTINEL_START" -v e="$SENTINEL_END" '
        $0 == s { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip
    ' "$rc" > "$tmp"
    {
        cat "$tmp"
        printf '%s\n' "$SENTINEL_START"
        printf '%s\n' "$line"
        printf '%s\n' "$SENTINEL_END"
    } > "$rc"
    rm -f "$tmp"
    say "wrote bootfire block in $rc"
}

wire_shell_hook() {
    if [ "${BOOTFIRE_NO_SHELL_HOOK:-0}" = "1" ]; then
        say "skipping shell hook (BOOTFIRE_NO_SHELL_HOOK=1)"
        return 0
    fi

    # Wire every shell the user has configured on this box. $SHELL is the
    # login shell, which often disagrees with the interactive shell (e.g.
    # $SHELL=zsh while the user lives in fish), so we don't trust it alone.
    wired=0
    posix_line="source $INSTALL_DIR/shell/$NAME.sh"

    if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/fish" ] || command -v fish >/dev/null 2>&1; then
        wire_fish
        wired=1
    fi
    if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
        wire_posix_rc "$HOME/.zshrc" "$posix_line"
        wired=1
    fi
    if [ -f "$HOME/.bashrc" ] || command -v bash >/dev/null 2>&1; then
        wire_posix_rc "$HOME/.bashrc" "$posix_line"
        wired=1
    fi

    if [ "$wired" -eq 0 ]; then
        warn "no supported shell detected; add the source line manually"
    fi
}

print_done_hint() {
    printf '\n'
    say "installed at $INSTALL_DIR"
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) warn "$BIN_DIR is not on \$PATH — add it to your shell rc" ;;
    esac
    printf '\nOpen a new shell, run `%s add <project-root>`, then `%s` to deploy.\n' "$NAME" "$NAME"
}

ensure_deps
fetch_repo
install_files
wire_shell_hook
print_done_hint
