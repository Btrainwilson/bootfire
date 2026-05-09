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

    set -l target (command bootfire $forward)
    test -z "$target"; and return 0
    cd "$target"; or return $status
    if test $cd_only -eq 0; and test -r ./start.sh
        source ./start.sh
    end
end
