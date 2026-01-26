{ lib, ... }:
{
  flake.nixosModules.core =
    { config, ... }:
    {
      options.custom = {
        programs.print-config = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          description = "Attrs of program and the command to print their config.";
        };
      };

      config = {
        custom.shell.packages =
          let
            cmds = config.custom.programs.print-config;
            ifBlocks = lib.concatMapAttrsStringSep "\n" (prog: cmd: ''
              "${prog}")
                ${cmd}
                ;;
            '') cmds;
            bashProgsStr = lib.concatMapAttrsStringSep ", " (prog: _: prog) cmds;
            bashProgsList = lib.concatMapAttrsStringSep " " (prog: _: ''"${prog}"'') cmds;
            fishCompletes = lib.concatMapAttrsStringSep "\n" (
              prog: _: ''complete -c print-config -a "${prog}"''
            ) cmds;
          in
          {
            print-config = {
              text = /* sh */ ''
                if [ -z "''${1-}" ]; then
                    echo "Usage: print-config [PROGRAM]"
                    exit 1
                fi

                case "$1" in
                    ${ifBlocks}
                    *)
                        echo "Error: Configuration for 'PROGRAM' not found or supported."
                        echo "Supported: ${bashProgsStr}"
                        exit 1
                        ;;
                esac
              '';

              completions.bash = /* sh */ ''
                _print_config_completions() {
                    local suggestions=(${bashProgsList})

                    # Generate completions based on the current word being typed
                    if [[ ''${COMP_CWORD} -eq 1 ]]; then
                      read -r -a COMPREPLY < <(compgen -W "''${suggestions[*]}" -- "''${COMP_WORDS[1]}")
                    fi
                }

                complete -F _print_config_completions print-config
              '';

              completions.fish = /* fish */ ''
                # Disable default file completions
                complete -c print-config -f

                # Add specific program arguments
                ${fishCompletes}
              '';
            };
          };
      };
    };
}
