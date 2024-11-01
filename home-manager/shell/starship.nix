{ lib, ... }:
{
  programs = {
    starship = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings =
        let
          dir_bg = "blue";
          accent_style = "bg:${dir_bg} fg:black";
          # divine orb style :)
          important_style = "bg:white fg:bold #ff0000";
        in
        {
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
            "$time"
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
          time = {
            format = "[ $time ]($style)";
            disabled = false;
            time_format = "%H:%M";
            style = accent_style;
          };
        };
    };

    fish = {
      # fix starship prompt to only have newlines after the first command
      # https://github.com/starship/starship/issues/560#issuecomment-1465630645
      shellInit = ''
        function prompt_newline --on-event fish_postexec
          echo ""
        end
      '';
      interactiveShellInit = lib.mkAfter ''
        function starship_transient_prompt_func
          starship module character
        end
      '';
    };

    # some sort of race condition with kitty and starship
    # https://github.com/kovidgoyal/kitty/issues/4476#issuecomment-1013617251
    kitty.shellIntegration.enableBashIntegration = false;
  };
}
