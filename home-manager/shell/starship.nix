{lib, ...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
        style = "blue";
      };
      # python = {
      #   format = "[$virtualenv]($style) ";
      #   style = "bright-black";
      # };
    };
  };

  programs.zsh.initExtra = ''
    # disable empty line when opening new terminal, but
    # insert empty line after each command for starship
    # https://github.com/starship/starship/issues/560#issuecomment-1318462079
    precmd() { precmd() { echo "" } }
  '';
}
