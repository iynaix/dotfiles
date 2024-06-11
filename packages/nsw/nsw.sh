nhArgs=()
restArgs=()
dots="@@dots@@"
hostname="@@host@@"
nhCommand="@@nhCommand@@"
isDry=$([ "$nhCommand" = "switch" ] && echo true || echo false)

while (( "$#" )); do
    case "$1" in
    -n|--dry)
        nhArgs+=("$1")
        isDry=true
        shift
        ;;
    -H|--hostname)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            # don't allow specifying hostname for switch / boot / test
            if [ "$nhCommand" = "build" ]; then
                hostname="$2"
            fi
            shift 2
        else
            echo "Error: Argument for hostname is missing" >&2
            exit 1
        fi
        ;;
    -s|--specialisation)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            nhArgs+=("$1" "$2")
            shift 2
        else
            echo "Error: Argument for specialisation is missing" >&2
            exit 1
        fi
        ;;
    -S|--no-specialisation)
        nhArgs+=("$1")
        shift
        ;;
    *) # everything else
        restArgs+=("$1")
        shift
        ;;
    esac
done

cd "$dots"

# stop bothering me about untracked files
untrackedFiles=$(git ls-files --exclude-standard --others .)
if [ -n "$untrackedFiles" ]; then
    git add "$untrackedFiles"
fi

nh os "$nhCommand" --hostname "$hostname" "${nhArgs[@]}" "$dots" -- "${restArgs[@]}"

# only relevant if --dry is not passed
if [ "$isDry" = true ]; then
    currentGeneration=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
    echo -e "Switched to Generation \033[1m$currentGeneration\033[0m"
fi
cd - > /dev/null