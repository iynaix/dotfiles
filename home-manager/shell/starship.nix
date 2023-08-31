{lib, ...}: {
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      line_break = {
        disabled = true;
      };
      format = lib.concatStringsSep "" [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$nix_shell"
        # "$cmd_duration"
        # "$line_break"
        # "$python"
        "$character"
      ];
      character = {
        error_symbol = "[❯](red)";
        success_symbol = "[❯](purple)";
        vimcmd_symbol = "[❮](green)";
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };
      directory = {
        style = "blue";
      };
      git_branch = {
        format = "[$branch]($style)";
        style = "yellow";
      };
      git_state = {
        format = "\([$state( $progress_current/$progress_total)]($style)\) ";
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
        symbol = "❄️ ";
        style = "blue";
      };
      # python = {
      #   format = "[$virtualenv]($style) ";
      #   style = "bright-black";
      # };
    };
  };

  # some sort of race condition with kitty and starship
  # https://github.com/kovidgoyal/kitty/issues/4476#issuecomment-1013617251
  programs.kitty.shellIntegration.enableBashIntegration = false;

  # fix starship prompt to only have newlines after the first command
  # reimplement enableBashIntegration and place at end of bashrc
  # https://github.com/starship/starship/issues/560#issuecomment-1651732556
  # programs.bash.initExtra = lib.mkOrder 2000 ''
  #   if [[ $TERM != "dumb" ]]; then
  #     precmd() {
  #         echo '''
  #     }
  #     export PROMPT_COMMAND=precmd

  #     eval "$(${config.home.profileDirectory}/bin/starship init bash --print-full-init)"
  #   fi
  # '';

  iynaix.persist = {
    home.directories = [
      ".cache/starship"
    ];
  };
}
