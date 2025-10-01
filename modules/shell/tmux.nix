{ lib, pkgs, ... }:
let
  inherit (lib) types;
  # implementation for loading plugins from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/tmux.nix
  tmuxPlugin = p: ''run-shell ${if types.package.check p then p.rtp else p.plugin.rtp}'';
  tmuxConf = # tmux
    ''
      # start with defaults from the Sensible plugin
      ${tmuxPlugin pkgs.tmuxPlugins.sensible}

      set  -g default-terminal "tmux-256color"
      set  -g base-index      1
      setw -g pane-base-index 1

      set -g status-keys vi
      set -g mode-keys   vi

      bind -N "Select pane to the left of the active pane" h select-pane -L
      bind -N "Select pane below the active pane" j select-pane -D
      bind -N "Select pane above the active pane" k select-pane -U
      bind -N "Select pane to the right of the active pane" l select-pane -R

      bind -r -N "Resize the pane left by 5" \
        H resize-pane -L 5
      bind -r -N "Resize the pane down by 5" \
        J resize-pane -D 5
      bind -r -N "Resize the pane up by 5" \
        K resize-pane -U 5
      bind -r -N "Resize the pane right by 5" \
        L resize-pane -R 5

      # rebind main key: C-Space
      unbind C-b
      set -g prefix C-Space
      bind -n -N "Send the prefix key through to the application" \
        C-Space send-prefix

      set  -g mouse             on
      set  -g focus-events      off
      setw -g aggressive-resize off
      setw -g clock-mode-style  24
      set  -s escape-time       500
      set  -g history-limit     2000

      # load plugins
      ${lib.concatMapStringsSep "\n" tmuxPlugin (
        with pkgs.tmuxPlugins;
        [
          vim-tmux-navigator
          yank
          tokyo-night-tmux
        ]
      )}

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
    '';
in
{
  custom.wrappers = [
    (_: _prev: {
      wrappers.tmux = {
        flags = {
          "-f" = pkgs.writeText "tmux.conf" tmuxConf;
        };
      };
    })
  ];

  environment.systemPackages = [ pkgs.tmux ];
}
