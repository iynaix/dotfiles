{
  config,
  pkgs,
  ...
}:
let
  # reloads fish completions whenever directories are added to $XDG_DATA_DIRS,
  # e.g. in nix shells or direnv
  fish-completion-sync = pkgs.fetchFromGitHub {
    owner = "iynaix";
    repo = "fish-completion-sync";
    rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
    hash = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
  };
in
{
  programs = {
    fish = {
      enable = true;
      # seems like shell abbreviations take precedence over aliases
      shellAbbrs = config.environment.shellAliases // {
        ehistory = ''nvim "${config.hj.xdg.data.directory}/fish/fish_history"'';
      };
      shellInit = # fish
      ''
        # shut up welcome message
        set fish_greeting

        # use vi key bindings with hybrid emacs keybindings
        function fish_user_key_bindings
            fish_default_key_bindings -M insert
            fish_vi_key_bindings --no-erase insert
        end

        # setup vi mode
        fish_vi_key_bindings

        # setup fish-completion-sync
        source ${fish-completion-sync}/init.fish
      ''
      # sponge options
      + ''
        # set options for plugins
        set sponge_regex_patterns 'password|passwd|^kill'

        # bind --mode default \t complete-and-search
      '';
    };
  };

  # fish plugins
  environment = {
    # install fish completions for fish
    # https://github.com/nix-community/home-manager/pull/2408
    pathsToLink = [ "/share/fish" ];

    systemPackages = [
      # do not add failed commands to history
      pkgs.fishPlugins.sponge
      fish-completion-sync
    ];
  };

  custom.persist = {
    home = {
      # fish history
      cache.directories = [ ".local/share/fish" ];
    };
  };
}
