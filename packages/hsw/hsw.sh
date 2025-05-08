#!/usr/bin/env bash

dots="@dots@"
hostname="@host@"
nhArgs=()
restArgs=()
nhCommand="switch"
showProgress=false

while (( "$#" )); do
    case "$1" in
    -n|--dry)
        nhArgs+=("$1")
        shift
        ;;
    -c|--configuration)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            # don't allow specifying configuration for switch
            shift 2
        else
            echo "Error: Argument for configuration is missing" >&2
            exit 1
        fi
        ;;
    --progress)
        showProgress=true
        shift
        ;;
    switch|build)
        nhCommand="$1"
        shift
        ;;
    *) # everything else
        restArgs+=("$1")
        shift
        ;;
    esac
done

pushd "$dots" > /dev/null

# stop bothering me about untracked files
untrackedFiles=$(git ls-files --exclude-standard --others .)
if [ -n "$untrackedFiles" ]; then
    git add "$untrackedFiles"
fi

if [ "$showProgress" = true ]; then
    home-manager "$nhCommand" --flake ".#$hostname" "${restArgs[@]}"
else
    nh home "$nhCommand" "$hostname" "${nhArgs[@]}" "$dots" -- "${restArgs[@]}"
fi

popd > /dev/null