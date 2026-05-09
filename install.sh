#!/bin/sh
# bootfire installer — for `curl | sh` use.
# For local development installs use `make install` instead.

set -eu

NAME="bootfire"
REPO_URL="${BOOTFIRE_REPO_URL:-https://github.com/CHANGE_ME/bootfire.git}"
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
        say "cloning $REPO_URL into $INSTALL_DIR"
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    fi
}

install_files() {
    mkdir -p "$BIN_DIR" "$CONFIG_DIR"
    chmod +x "$INSTALL_DIR/bin/$NAME-core"
    ln -sf "$INSTALL_DIR/bin/$NAME-core" "$BIN_DIR/$NAME-core"
    [ -e "$CONFIG_DIR/config" ] || cp "$INSTALL_DIR/share/default-config" "$CONFIG_DIR/config"
    [ -e "$CONFIG_DIR/ignore" ] || cp "$INSTALL_DIR/share/default-ignore" "$CONFIG_DIR/ignore"
}

print_shell_hint() {
    printf '\n'
    say "installed at $INSTALL_DIR"
    case "${SHELL:-}" in
        */fish)
            printf '\nAdd to ~/.config/fish/config.fish:\n  source %s/shell/%s.fish\n' "$INSTALL_DIR" "$NAME"
            ;;
        */zsh)
            printf '\nAdd to ~/.zshrc:\n  source %s/shell/%s.sh\n' "$INSTALL_DIR" "$NAME"
            ;;
        *)
            printf '\nAdd to ~/.bashrc (or your shell rc):\n  source %s/shell/%s.sh\n' "$INSTALL_DIR" "$NAME"
            ;;
    esac
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) printf '\n'; warn "$BIN_DIR is not on \$PATH — add it before sourcing the shell file." ;;
    esac
    printf '\nThen open a new shell, run `%s add <project-root>`, and `%s` to deploy.\n' "$NAME" "$NAME"
}

ensure_deps
fetch_repo
install_files
print_shell_hint
