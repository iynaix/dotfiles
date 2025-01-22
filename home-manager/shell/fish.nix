{
  config,
  lib,
  pkgs,
  ...
}:
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
      };
      # use abbreviations instead of aliases
      preferAbbrs = true;
      # seems like shell abbreviations take precedence over aliases
      shellAbbrs = config.home.shellAliases // {
        ehistory = "nvim ${config.xdg.dataHome}/fish/fish_history";
      };
      shellInit = ''
        # shut up welcome message
        set fish_greeting

        # set options for plugins
        set sponge_regex_patterns 'password|passwd'

        # bind --mode default \t complete-and-search
      '';
      # setup vi mode
      interactiveShellInit = ''
        fish_vi_key_bindings
      '';
    };
  };

  # fish plugins, home-manager's programs.fish.plugins has a weird format
  home.packages = with pkgs.fishPlugins; [
    # do not add failed commands to history
    sponge
  ];

  # set as default interactive shell
  programs.kitty.settings.shell = lib.mkForce (lib.getExe pkgs.fish);
  programs.ghostty.settings.command = lib.mkForce (lib.getExe pkgs.fish);

  custom.persist = {
    home = {
      cache.directories = [ ".local/share/fish" ];
    };
  };
}
