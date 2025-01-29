#!/usr/bin/env bash

dots="@dots@"
hostname="@host@"
nhArgs=()
restArgs=()
hostnameOverride="$hostname"
nhCommand="switch"
showProgress=false

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
    --progress)
        showProgress=true
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

if [ "$showProgress" = true ]; then
    # use remote sudo only uses sudo during the switch to the new generation
    nixos-rebuild "$nhCommand" --use-remote-sudo --flake ".#$hostname" "${restArgs[@]}"
else
    nh os "$nhCommand" --hostname "$hostname" "${nhArgs[@]}" "$dots" -- "${restArgs[@]}"
fi

if [ "$nhCommand" = "switch" ] || [ "$nhCommand" = "boot" ]; then
    currentGeneration=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
    echo -e "Switched to Generation \033[1m$currentGeneration\033[0m"
fi
popd > /dev/null