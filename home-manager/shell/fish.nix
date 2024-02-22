{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.shell;
in
{
  programs = {
    fish = {
      enable = true;
      functions = {
        # use vi key bindings with hybrid emacs keybindings
        fish_user_key_bindings = ''
          fish_default_key_bindings -M insert
          fish_vi_key_bindings --no-erase insert
        '';
      } // lib.mapAttrs (_: value: if lib.isString value then value else value.fishBody) cfg.functions;
      plugins = [
        # transient prompt because starship's transient prompt does not handle empty commands
        {
          name = "transient.fish";
          src = pkgs.fetchFromGitHub {
            owner = "zzhaolei";
            repo = "transient.fish";
            rev = "4fe72ab8481a1133461a2d49f24dc99835921ece";
            hash = "sha256-0jN+5c58WW8RstQDEF1PajWHKfzKjjfcUXA3p1LsdIc=";
          };
        }
        # do not add failed commands to history
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
      ];
      shellAliases = {
        ehistory = "nvim ${config.xdg.dataHome}/fish/fish_history";
      };
      shellInit = ''
        # shut up welcome message
        set fish_greeting

        # set options for plugins
        set sponge_regex_patterns 'password|passwd'
      '';
      # setup vi mode
      interactiveShellInit = ''
        fish_vi_key_bindings
      '';
    };
  };

  # set as default interactive shell
  programs.kitty.settings.shell = lib.mkForce (lib.getExe pkgs.fish);
  custom.ghostty.config.command = lib.mkForce (lib.getExe pkgs.fish);

  # create completion files as needed
  xdg.configFile = lib.pipe cfg.functions [
    (lib.filterAttrs (_: value: lib.isAttrs value && value.fishCompletion != ""))
    (lib.mapAttrs' (
      name: value:
      lib.nameValuePair "fish/completions/${name}.fish" {
        text = ''
          function _${name}
          ${value.fishCompletion}
          end
          complete --no-files --command ${name} --arguments "(_${name})"
        '';
      }
    ))
  ];

  custom.persist = {
    home = {
      cache = [ ".local/share/fish" ];
    };
  };
}
