{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkForce;
  fishPath = getExe config.programs.fish.package;
in
{
  programs = {
    fish = {
      enable = true;
      functions = {
        # use vi key bindings with hybrid emacs keybindings
        fish_user_key_bindings = # fish
          ''
            fish_default_key_bindings -M insert
            fish_vi_key_bindings --no-erase insert
          '';
      };
      # use abbreviations instead of aliases
      preferAbbrs = true;
      # seems like shell abbreviations take precedence over aliases
      shellAbbrs = config.home.shellAliases // {
        ehistory = "nvim ${config.xdg.dataHome}/fish/fish_history";
      };
      shellInit = # fish
        ''
          # shut up welcome message
          set fish_greeting

          # set options for plugins
          set sponge_regex_patterns 'password|passwd|^kill'

          # bind --mode default \t complete-and-search
        '';
      # setup vi mode
      interactiveShellInit = # fish
        ''
          fish_vi_key_bindings
        '';

      # fish plugins, must be an attrset
      plugins = [
        # do not add failed commands to history
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
        # reloads fish completions whenever directories are added to $XDG_DATA_DIRS,
        # e.g. in nix shells or direnv
        {
          name = "fish-completion-sync";
          src = pkgs.fetchFromGitHub {
            owner = "iynaix";
            repo = "fish-completion-sync";
            rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
            hash = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
          };
        }
      ];
    };
  };

  # set as default interactive shell, also set $SHELL for nix shell to pick up
  programs.ghostty.settings = {
    command = mkForce "SHELL=${fishPath} ${fishPath}";
  };

  custom.persist = {
    home = {
      cache.directories = [ ".local/share/fish" ];
    };
  };
}
