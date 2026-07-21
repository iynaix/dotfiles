{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages =
        let
          accent_bg = "blue";
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
                "$directory(${accent_bg}) "
                "$git_branch"
                "$git_state"
                "$git_status"
                "$nix_shell"
                " "
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
                style = "bold bg:${accent_bg} fg:black";
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
                format = "[$symbol]($style) ";
                symbol = "";
                style = "bright-magenta";
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

      # NOTE: starship is initialized in the fish wrapper

      custom.programs.print-config = {
        starship = /* sh */ "moor ${pkgs.starship.configuration.constructFiles."starship.toml"}";
      };
    };
}
