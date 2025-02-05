{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    prefix = "C-Space";
    mouse = true;
    keyMode = "vi";
    clock24 = true;
    baseIndex = 1; # index panes and windows from 1
    customPaneNavigationAndResize = true; # use vim keys to navigate panes
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
      catppuccin
    ];

    extraConfig = # tmux
      ''
        # Allow true color support
        set -ga terminal-overrides ",*:RGB"
        # Allow changing cursor shape
        set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

        # Keybinds
        bind BSpace confirm kill-session
        unbind r
        bind r source-file ~/.config/tmux/tmux.conf

        # Saner splitting.
        bind v split-window -h
        bind s split-window -v

        # Activity
        setw -g monitor-activity off
        set -g visual-activity off

        # Automatically set window title
        setw -g automatic-rename on
        set -g set-titles on

        # Transparent tmux background
        set -g window-style "bg=terminal"
        set -g window-active-style "bg=terminal"

        # Customize tmux catppuccin, needs to be done after plugin is loaded
        set -g @catppuccin_status_background "none"
        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left ""
        set -g status-right "#{E:@catppuccin_status_application}"
        set -ag status-right "#{E:@catppuccin_status_session}"
      '';
  };
}
