_: {
  programs.tmux = {
    enable = true;
    prefix = "C-b";
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    escapeTime = 0; # no delay for esc key press
    baseIndex = 1; # index panes and windows from 1
    customPaneNavigationAndResize = true; # use vim keys to navigate panes
    extraConfig = ''
      # Saner splitting.
      bind v split-window -h
      bind s split-window -v

      # 16 million colors please
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

      # Activity
      setw -g monitor-activity off
      set -g visual-activity off

      # Automatically set window title
      setw -g automatic-rename on
      set -g set-titles on

      # Cleaner status bar
      set -g status-style bg=default
      # set -g status-position top

      set -g status-left ""
      set -g status-right ""

      set -g pane-border-style bg=default,fg=colour8
      set -g pane-active-border-style bg=default,fg=colour7

      set -g message-style bg=colour8,fg=colour0

      setw -g window-status-format "#[fg=colour7,nobold,nounderscore,noitalics] #[fg=colour7] #W #[fg=colour0,nobold,nounderscore,noitalics]"
      setw -g window-status-style bg=default,fg=colour7

      setw -g window-status-current-style bg=default,fg=colour7
      setw -g window-status-current-format "#[fg=colour0,nobold,nounderscore,noitalics] #[fg=colour4] #W #[fg=colour0,nobold,nounderscore,noitalics]"

      setw -g window-status-activity-style fg=colour8
    '';
  };
}
