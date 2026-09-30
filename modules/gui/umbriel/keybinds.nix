{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      libCustom,
      user,
      ...
    }:
    {
      custom.programs = {
        umbriel.settings = {
          keybinds =
            let
              termExec = cmd: "spawn:kitty ${cmd}";
              emacsExec = elisp: "spawn:emacs-launcher '${elisp}'";
            in
            # shared keybinds
            {
              "Mod+Return" = "spawn:kitty";
              "Mod+Shift+Return" = "spawn:noctalia msg panel-toggle launcher";

              "Mod+E" = "spawn:nemo /home/${user}/Downloads";
              "Mod+Shift+E" = "spawn:${termExec "yazi /home/${user}/Downloads"}";

              "Mod+W" = "spawn:helium --profile-directory=Default";
              "Mod+Shift+W" = "spawn:helium --profile-directory=Default --incognito";

              "Mod+V" = "spawn:emacsclient -c";
              "Mod+Shift+V" = termExec "nvim";

              "Mod+period" = emacsExec ''(projectile-find-file-in-directory "/persist/home/${user}/projects")'';
              "Mod+Shift+period" =
                emacsExec ''(projectile-find-file-in-directory "/persist/home/${user}/projects/nixpkgs")'';

              "Ctrl+Alt+Delete" = "spawn:noctalia msg panel-toggle session";

              # toggle the bar
              "Mod+A" = "spawn:noctalia msg bar-toggle";

              # restart noctalia
              "Mod+Shift+A" = "spawn:noctalia-reload";

              # clipboard history
              "Mod+Ctrl+V" = "spawn:noctalia msg panel-toggle clipboard";

              # notification history
              "Mod+N" = "spawn:noctalia msg panel-toggle control-center notifications";

              # picture in picture mode
              # "Mod+P"= "spawn:wm-pip";

              "Mod+Apostrophe" = "spawn:wallpaper select";
              "Alt+Apostrophe" = "spawn:wallpaper history";

              # audio buttons
              "XF86AudioLowerVolume" = {
                action = "spawn:pamixer -d 5";
                allow_when_locked = true;
              };
              "XF86AudioRaiseVolume" = {
                action = "spawn:pamixer -i 5";
                allow_when_locked = true;
              };
              "XF86AudioMute" = {
                action = "spawn:pamixer -t";
                allow_when_locked = true;
              };
            }
            // {
              "Mod+BackSpace" = {
                action = "window-close";
                repeat = false;
              };

              # exit umbriel
              "Alt+F4" = "session-quit";

              # TODO: reset monitors?
              # "CTRL_SHIFT, Escape, exec, umbriel-monitors"

              # Open/close the Overview: a zoomed-out view of workspaces and windows.
              # You can also move the mouse into the top-left hot corner,
              # or do a four-finger swipe up on a touchpad.
              "Mod+O" = "overview-toggle";

              "Mod+H" = "window-focus-or-output-left";
              "Mod+J" = "window-focus-or-workspace-down";
              "Mod+K" = "window-focus-or-workspace-up";
              "Mod+L" = "window-focus-or-output-right";

              "Mod+Shift+H" = "window-move-or-output-left";
              "Mod+Shift+J" = "window-move-or-workspace-down";
              "Mod+Shift+K" = "window-move-or-workspace-up";
              "Mod+Shift+L" = "window-move-or-output-right";

              "Mod+Home" = "column-focus-first";
              "Mod+End" = "column-focus-last";
              "Mod+Shift+Home" = "column-move-to-first";
              "Mod+Shift+End" = "column-move-to-last";

              "Mod+Left" = "output-focus-left";
              "Mod+Down" = "output-focus-down";
              "Mod+Up" = "output-focus-up";
              "Mod+Right" = "output-focus-right";

              "Mod+Shift+Left" = "column-move-to-output-left";
              "Mod+Shift+Down" = "column-move-to-output-down";
              "Mod+Shift+Up" = "column-move-to-output-up";
              "Mod+Shift+Right" = "column-move-to-output-right";

              # toggle between prev and current windows
              "Mod+grave" = "window-focus-last";

              # cycle windows (classic alt tab in a workspace)
              "Alt+Tab" = "window-focus-next";
              "Alt+SHIFT+Tab" = "window-focus-last";

              # cycle between windows of the same class
              "CTRL+ALT+Tab" = "spawn:wm-same-class next";
              "CTRL+ALT+SHIFT+Tab" = "spawn:wm-same-class prev";

              # Switches focus between the current and the previous workspace.
              "Mod+Tab" = "workspace-focus-last";

              # TODO: picture in picture mode
              # "Mod+P" = "spawn:wm-pip";

              # The following binds move the focused window in and out of a column.
              # If the window is alone, they will consume it into the nearby column to the side.
              # If the window is already in a column, they will expel it out.
              "Mod+BracketLeft" = "window-consume-or-expel-left";
              "Mod+BracketRight" = "window-consume-or-expel-right";

              "Mod+R" = "window-cycle-primary-extent";
              "Mod+Shift+R" = "window-cycle-secondary-extent";

              "Mod+Z" = "window-toggle-maximize";
              "Mod+F" = "window-toggle-fullscreen";
              "Mod+G" = "window-toggle-floating";

              "Mod+S" = "window-toggle-pinned";

              "Mod+C" = "window-center";
              "Mod+Ctrl+C" = "column-center";

              # mouse bindings

              # having Mod + Scroll up / Down is impossible to control with trackball, so require Shift for workspaces
              "Mod+Shift+WheelDown" = "window-focus-or-workspace-down";
              "Mod+Shift+WheelUp" = "window-focus-or-workspace-up";

              "Mod+WheelRight" = "window-focus-or-output-right";
              "Mod+WheelLeft" = "window-focus-or-output-left";
            }
            //
              # keybinds for workspace switch / move
              (
                config.custom.hardware.monitors
                |> libCustom.mapWorkspaces (
                  { workspace, key, ... }:
                  [
                    {
                      # Switch workspaces with mainMod + [0-9]
                      "Mod+${key}" = ''workspace-switch:"${toString workspace}"'';
                      # Move active window to a workspace with mainMod + SHIFT + [0-9]
                      "Mod+Shift+${key}" = ''window-move-to-workspace:"${toString workspace}"'';
                    }
                  ]
                )
                |> lib.flatten
                |> lib.mergeAttrsList
              );
        };
      };
    };
}
