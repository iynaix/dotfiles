{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages =
        let
          dir_bg = "blue";
          accent_style = "bg:${dir_bg} fg:black";
          # divine orb style :)
          important_style = "bg:white fg:bold #ff0000";
        in
        {
          starship = inputs.wrappers.wrappers.starship.wrap {
            inherit pkgs;
            settings = {
              add_newline = false;
              format = lib.concatStrings [
                # begin left format
                "$username"
                "$hostname"
                "$directory[](${dir_bg}) "
                "$git_branch"
                "$git_state"
                "$git_status"
                "$nix_shell"
                # end left format
                "$fill"
                # begin right format
                "[](${dir_bg})"
                "[ ](${accent_style})"
                "$cmd_duration"
                # end right format
                "$line_break"
                "$character"
              ];

              # modules
              character = {
                error_symbol = "[ ](bold red)";
                success_symbol = "[](purple)";
                vimcmd_symbol = "[](green)";
              };
              username = {
                style_root = important_style;
                style_user = important_style;
                format = "[ $user ]($style) in ";
              };
              hostname = {
                style = important_style;
              };
              directory = {
                format = "[ $path ]($style)";
                style = accent_style;
              };
              git_branch = {
                symbol = "";
                format = "on [$symbol $branch]($style)";
                style = "yellow";
              };
              git_state = {
                format = "([$state( $progress_current/$progress_total)]($style)) ";
                style = "bright-black";
              };
              git_status = {
                conflicted = "​";
                deleted = "​";
                format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style) ";
                modified = "​";
                renamed = "​";
                staged = "​";
                stashed = "≡";
                style = "cyan";
                untracked = "​";
              };
              nix_shell = {
                format = "[$symbol]($style)";
                symbol = "";
                style = "bright-magenta";
              };
              fill = {
                symbol = " ";
              };
              line_break = {
                disabled = false;
              };
              cmd_duration = {
                format = "[ $duration ]($style)";
                disabled = false;
                min_time = 0;
                show_milliseconds = false;
                style = accent_style;
              };
            };
          };
        };
    };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          inherit (pkgs.custom) starship;
        })
      ];

      # NOTE: starship is overlay-ed above
      environment.systemPackages = [
        pkgs.starship
      ];

      programs = {
        bash = {
          promptInit = /* sh */ ''
            if [[ $TERM != "dumb" ]]; then
              eval "$(starship init bash)"
            fi
          '';
        };

        fish = {
          # fix starship prompt to only have newlines after the first command
          # https://github.com/starship/starship/issues/560#issuecomment-1465630645
          promptInit = /* fish */ ''
            if test "$TERM" != dumb
              # not sure why this needs to be explicitly set, but wrapping alone does not seem sufficient
              starship init fish | source
              enable_transience
            end

            function prompt_newline --on-event fish_postexec
              echo ""
            end

            function starship_transient_prompt_func
              starship module character
            end
          '';
        };
      };

      custom.programs.print-config = {
        starship = /* sh */ "moor ${pkgs.starship.configuration.constructFiles."starship.toml"}";
      };
    };
}
