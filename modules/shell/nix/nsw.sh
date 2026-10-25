#!/usr/bin/env bash

dots="@dots@"
hostname="@host@"
specialisation="@specialisation@"
nhArgs=()
restArgs=()
hostnameOverride="$hostname"
nhCommand="switch"

while (( "$#" )); do
    case "$1" in
    -n|--dry)
        nhArgs+=("$1")
        shift
        ;;
    -H|--hostname)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            hostnameOverride="$2"
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
    # unknown flags go to nh (before --)
    -*)
        nhArgs+=("$1")
        shift
        ;;
    switch|boot|test|build)
        nhCommand="$1"
        shift
        ;;
    *) # everything else
        restArgs+=("$1")
        shift
        ;;
    esac
done

# only allow hostname override for build
if [ "$nhCommand" = "build" ]; then
    hostname="$hostnameOverride"
fi

pushd "$dots" > /dev/null

# stop bothering me about untracked files
untrackedFiles=$(git ls-files --exclude-standard --others .)
if [ -n "$untrackedFiles" ]; then
    git add "$untrackedFiles"
fi

specialisationArgs=()
if [ -n "$specialisation" ]; then
   specialisationArgs=("--specialisation" "$specialisation")
fi

cmd=(
    nh os "$nhCommand"
    --hostname "$hostname"
    "${specialisationArgs[@]}"
    "${nhArgs[@]}"
    "$dots"
    --
    "${restArgs[@]}"
)

printf '%q ' "${cmd[@]}"; echo

"${cmd[@]}"

if [ $? -eq 0 ]; then
    if [ "$nhCommand" = "switch" ] || [ "$nhCommand" = "boot" ]; then
        currentGeneration=$(nh os info | grep -m 1 current | awk '{print $1}')
        echo -e "Switched to Generation \033[1m$currentGeneration\033[0m"
    fi
fi

popd > /dev/null
