# Source this file from ~/.bashrc or ~/.zshrc:
#   source ~/.local/share/bootfire/shell/bootfire.sh

bootfire() {
    if [ $# -gt 0 ]; then
        case "$1" in
            add|rm|list|--edit|-h|--help|--bump)
                command bootfire "$@"
                return $?
                ;;
        esac
    fi

    local cd_only=0
    local -a forward=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            -c|--cd-only) cd_only=1 ;;
            *) forward+=("$arg") ;;
        esac
    done

    local target
    target="$(command bootfire "${forward[@]}")"
    [ -n "$target" ] || return 0
    cd -- "$target" || return $?
    command bootfire --bump "$target"
    if [ "$cd_only" -eq 0 ] && [ -x ./start.sh ]; then
        ./start.sh
    fi
}
