{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.shell;
in {
  programs.fish = {
    enable = true;
    functions = lib.mapAttrs (name: value:
      if lib.isString value
      then value
      else value.fishBody)
    cfg.functions;
    shellAliases = {
      ehistory = "nvim ~/.local/share/fish/fish_history";
    };
    shellInit = ''
      # shut up welcome message
      set fish_greeting

      # fix starship prompt to only have newlines after the first command
      # https://github.com/starship/starship/issues/560#issuecomment-1465630645
      function postexec_newline --on-event fish_postexec
        echo ""
      end

      ${cfg.initExtra}
    '';
  };

  # create completion files as needed
  xdg.configFile = lib.pipe cfg.functions [
    (lib.filterAttrs (name: value: lib.isAttrs value && value.fishCompletion != ""))
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

  iynaix.persist.home.directories = [
    ".local/share/fish"
  ];
}
