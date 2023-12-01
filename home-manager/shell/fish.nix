{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.iynaix.shell;
in {
  programs.fish = {
    enable = true;
    functions = lib.mapAttrs (_: value:
      if lib.isString value
      then value
      else value.fishBody)
    cfg.functions;
    shellAliases = {
      ehistory = "nvim ~/.local/share/fish/fish_history";
    };
    shellInit =
      ''
        # shut up welcome message
        set fish_greeting

        # fix starship prompt to only have newlines after the first command
        # https://github.com/starship/starship/issues/560#issuecomment-1465630645
        function postexec_newline --on-event fish_postexec
          echo ""
        end

        # fish doesn't seem to pick up completions for dotfiles_utils?
        set --append fish_complete_path "${pkgs.iynaix.dotfiles-utils}/share/fish/vendor_completions.d"
      ''
      # wallust colorscheme
      + lib.optionalString (config.iynaix.wallust.enable) ''
        set wallust_colors "/home/${user}/.cache/wallust/sequences"
        if test -e "$wallust_colors"
            command cat "$wallust_colors"
        end
      '';
  };

  # create completion files as needed
  xdg.configFile = lib.pipe cfg.functions [
    (lib.filterAttrs (_: value: lib.isAttrs value && value.fishCompletion != ""))
    (lib.mapAttrs' (name: value:
      lib.nameValuePair "fish/completions/${name}.fish" {
        text = ''
          function _${name}
          ${value.fishCompletion}
          end
          complete --no-files --command ${name} --arguments "(_${name})"
        '';
      }))
  ];

  iynaix.persist = {
    home.directories = [
      ".local/share/fish"
    ];
  };
}
