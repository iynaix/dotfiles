{ inputs, lib, ... }:
let
  # position defaults to anywhere for some strange reason?
  # TODO: remove when https://github.com/BirdeeHub/nix-wrapper-modules/pull/583 is merged
  fix-completion-position = lib.mapAttrs (
    _k: v:
    if lib.isString v then
      {
        expansion = v;
        position = "command";
      }
    else
      v
  );
in
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages =
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
          fish = inputs.wrappers.wrappers.fish.wrap rec {
            inherit pkgs;

            flags = {
              # allow extra config from nixos programs.fish, such as direnv setup etc
              "--no-config" = false;
            };

            runtimePkgs =
              (with self'.packages; [
                bat # includes batman
                eza
                eza-tree
                git
                moor
                neovim-iynaix
                ripgrep
                starship
                yazi
              ])
              ++ [
                pkgs.zoxide
              ];

            # create the shell abbrs from passthru.shellAliases in runtimePkgs
            abbreviations = fix-completion-position (
              {
                ":e" = "nvim";
                ":q" = "exit";
                ":wq" = "exit";
                c = "clear";
                cat = "bat";
                ccat = "command cat";
                cp = "cp -ri";
                crate = "cargo";
                isodate = "date -u '+%Y-%m-%dT%H:%M:%SZ'";
                man = "batman";
                mime = "xdg-mime query filetype";
                mkdir = "mkdir -p";
                mount = "mount --mkdir";
                mv = "mv -i";
                nano = "nvim";
                neovim = "nvim";
                open = "xdg-open";
                ping = "ping -c 5";
                py = "python";
                rm = "rm -I";
                sl = "ls";
                v = "nvim";
                w = "watch -cn1 -x cat";

                # zoxide included in runtimePkgs
                z = "zoxide query -i";

                # cd aliases
                ".." = "cd ..";
                "..." = "cd ../..";
              }
              # extract the shellAliases and abbrs from each runtimePkg
              // (
                runtimePkgs
                |> map (p: (p.passthru.shellAliases or { }) // (p.passthru.abbreviations or { }))
                |> lib.mergeAttrsList
              )
            );

            plugins = [
              # do not add failed commands to history
              pkgs.fishPlugins.sponge
            ];

            configFile.content = /* fish */ ''
              # shut up welcome message
              set fish_greeting

              if status is-interactive
                # use vi key bindings with hybrid emacs keybindings
                function fish_user_key_bindings
                    fish_default_key_bindings -M insert
                    fish_vi_key_bindings --no-erase insert
                end

                # setup vi mode
                fish_vi_key_bindings

                # setup fish-completion-sync
                source ${fish-completion-sync}/init.fish

                # set options for sponge
                set sponge_regex_patterns 'password|passwd|^kill'

                # setup zoxide
                ${lib.getExe pkgs.zoxide} init fish --cmd cd | source

                # setup starship
                if test "$TERM" != dumb
                    starship init fish | source
                    enable_transience
                end

                # fix starship prompt to only have newlines after the first command
                # https://github.com/starship/starship/issues/560#issuecomment-2409922650
                function prompt_newline --on-event fish_postexec
                    echo ""
                end

                function starship_transient_prompt_func
                    # tput cuu1
                    starship module character
                end

                # abbreviation expansion is broken for --help, remove when
                # https://github.com/BirdeeHub/nix-wrapper-modules/pull/583 is merged
                abbr --add  --position anywhere    -- --help "--help | bat --plain --language=help"
              end
            '';
          };
        };
    };

  flake.modules.nixos.core =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.custom.constants) user;
    in
    {
      nixpkgs.overlays = [
        (_: _prev: {
          fish = pkgs.custom.fish;
        })
      ];

      users.users.${user}.shell = pkgs.fish; # overlay-ed above

      programs.fish = {
        enable = true;
        # use abbrs instead of aliases
        shellAliases = lib.mkForce { };
        shellAbbrs = config.environment.shellAliases // {
          ehistory = ''nvim "${config.hj.xdg.data.directory}/fish/fish_history"'';
        };
      };

      environment = {
        # install fish completions for fish
        # https://github.com/nix-community/home-manager/pull/2408
        pathsToLink = [ "/share/fish" ];
      };

      custom.persist = {
        home = {
          # fish history
          cache.directories = [
            ".local/share/fish"
            ".local/share/zoxide"
          ];
        };
      };
    };
}
