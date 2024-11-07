_: {
  home.shellAliases = {
    t = "tree";
  };

  custom.shell.packages = {
    tree = ''
      if [ $# -eq 0 ]; then
          echo "No arguments provided"
          exit 1
      fi

      # Get all arguments except the last one
      args=("''${@:1:$#-1}")

      # Get the last argument
      last_arg="''${!#}"

      if [ -L "$last_arg" ]; then
          set -- "''${args[@]}" "$(readlink -f "$last_arg")"
      else
          # If it's not a symlink, keep the original arguments
          set -- "$@"
      fi

      # run eza with resolved arguments
      eza -la --git-ignore --icons --tree --hyperlink --level 3 "$@"
    '';
  };

  programs.eza = {
    enable = true;
    icons = "always";
    enableBashIntegration = true;
    enableFishIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--octal-permissions"
      "--hyperlink"
    ];
  };
}
