{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.tmux = inputs.wrappers.wrappers.tmux.wrap {
        inherit pkgs;
        prefix = "C-Space";
        terminal = "tmux-256color";

        terminalOverrides = lib.concatStringsSep "," [
          # Allow true color support
          ",*:RGB"
          # Allow changing cursor shape
          "*:Ss=\E[%p1%d q:Se=\E[ q"
        ];

        statusKeys = "vi";
        modeKeys = "vi";

        escapeTime = 500;
        vimVisualKeys = true;

        plugins = with pkgs.tmuxPlugins; [
          vim-tmux-navigator
          yank
          tokyo-night-tmux
        ];

        configAfter = /* tmux */ ''
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

          set  -g focus-events      off

          # Keybinds
          bind BSpace confirm kill-session
          unbind r
          bind r source-file ~/.config/tmux/tmux.conf

          # Saner splitting.
          bind v split-window -h
          bind s split-window -v

          # Activity
          setw -g monitor-activity off

          # Automatically set window title
          setw -g automatic-rename on
          set -g set-titles on

          # Transparent tmux background
          set -g window-style "bg=terminal"
          set -g window-active-style "bg=terminal"
        '';
      };
    };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          tmux = pkgs.custom.tmux;
        })
      ];

      environment.systemPackages = [
        pkgs.tmux # overlay-ed above
      ];

      custom.programs.print-config = {
        tmux = /* sh */ ''moor "${pkgs.tmux.configuration.flags."-f".data}"'';
      };
    };
}
