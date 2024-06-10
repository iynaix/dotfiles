{
  git,
  nh,
  writeShellApplication,
  # variables
  dots ? "$HOME/projects/dotfiles",
  name ? "hsw",
  host ? "desktop",
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    git
    nh
  ];
  text = ''
    nhArgs=()
    restArgs=()

    while (( "$#" )); do
      case "$1" in
        -n|--dry)
          nhArgs+=("$1")
          shift
          ;;
        -c|--configuration)
          if [ -n "$2" ] && [ "''${2:0:1}" != "-" ]; then
            # don't allow specifying configuration for switch
            shift 2
          else
            echo "Error: Argument for configuration is missing" >&2
            exit 1
          fi
          ;;
        *) # everything else
          restArgs+=("$1")
          shift
          ;;
      esac
    done

    cd "${dots}"

    # stop bothering me about untracked files
    untrackedFiles=$(git ls-files --exclude-standard --others .)
    if [ -n "$untrackedFiles" ]; then
        git add "$untrackedFiles"
    fi

    nh home switch --configuration "${host}" "''${nhArgs[@]}" "${dots}" -- "''${restArgs[@]}"

    cd - > /dev/null
  '';
}
