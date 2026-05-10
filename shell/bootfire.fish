function bootfire --description "Fuzzy-find a project directory and run start.sh"
    if test (count $argv) -gt 0
        switch $argv[1]
            case add rm list --edit -h --help
                command bootfire $argv
                return $status
        end
    end

    set -l cd_only 0
    set -l forward
    for arg in $argv
        switch $arg
            case -c --cd-only
                set cd_only 1
            case '*'
                set -a forward $arg
        end
    end

    # fish does not propagate stdin into `(...)` command substitution,
    # so capture piped lines here and re-pipe them into the binary.
    set -l stdin_lines
    if not isatty stdin
        while read -l line
            set -a stdin_lines $line
        end
    end

    set -l target
    if test (count $stdin_lines) -gt 0
        set target (printf '%s\n' $stdin_lines | command bootfire $forward)
    else
        set target (command bootfire $forward)
    end
    test -z "$target"; and return 0
    cd "$target"; or return $status
    if test $cd_only -eq 0; and test -r ./start.sh
        source ./start.sh
    end
end
