{ lib, ... }: {
  flake.modules.nixos.core = {
    options.custom.wm = {
      binds = lib.mkOption {
        description = "Keybinds shared across all WMs";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              spawn = lib.mkOption {
                type = lib.types.str;
                description = "Command to execute";
              };
              hyprlandArgs = lib.mkOption {
                type = lib.types.attrs;
                description = "Additional args to be used by hyprland";
              };
              niriArgs = lib.mkOption {
                type = lib.types.attrs;
                description = "Additional args to be used by niri";
              };
            };
          }
        );
      };
    };
  };

  flake.modules.nixos.wm =
    # shared keybinds across all WMs
    { config, ... }:
    let
      inherit (config.custom.constants) dots projects;
      termExec = cmd: "ghostty -e ${cmd}";
      emacsExec = elisp: "emacs-launcher ${elisp}";
    in
    {
      custom.wm.binds = {
        "Mod+Return".spawn = "ghostty";
        "Mod+Shift+Return".spawn = "noctalia-ipc launcher toggle";

        "Mod+E".spawn = "nemo ${config.hj.directory}/Downloads";
        "Mod+Shift+E".spawn = termExec "yazi ${config.hj.directory}/Downloads";

        # background process to workaround a race condition that causes helium to only open sometimes on niri
        "Mod+W".spawn = "helium --profile-directory=Default &";
        "Mod+Shift+W".spawn = "helium --profile-directory=Default --incognito &";

        "Mod+V".spawn = "emacsclient -c";
        # "Mod+Shift+V".spawn = "noctalia-ipc plugin:projects toggle";
        "Mod+Shift+V".spawn =
          emacsExec "(projectile-discover-projects-in-search-path) (projectile-switch-project)";

        "Mod+period".spawn = emacsExec ''(projectile-find-file-in-directory "${dots}")'';
        "Mod+Shift+period".spawn = emacsExec ''(projectile-find-file-in-directory "${projects}/nixpkgs")'';

        "Ctrl+Alt+Delete".spawn = "noctalia-ipc sessionMenu toggle";

        # toggle the bar
        "Mod+A".spawn = "noctalia-ipc bar toggle";

        # restart noctalia
        "Mod+Shift+A".spawn = "noctalia-reload";

        # clipboard history
        "Mod+Ctrl+V".spawn = "noctalia-ipc launcher clipboard";

        # notification history
        "Mod+N".spawn = "noctalia-ipc notifications toggleHistory";

        # picture in picture mode
        "Mod+P".spawn = "wm-pip";

        "Mod+Apostrophe".spawn = "wallpaper rofi";
        # "Mod+Shift+Apostrophe".spawn = "rofi-wallust-theme";
        "Alt+Apostrophe".spawn = "wallpaper history";

        # audio buttons
        "XF86AudioLowerVolume" = {
          spawn = "pamixer -d 5";
          hyprlandArgs = {
            locked = true;
          };
          niriArgs = {
            allow-when-locked = true;
          };
        };
        "XF86AudioRaiseVolume" = {
          spawn = "pamixer -i 5";
          hyprlandArgs = {
            locked = true;
          };
          niriArgs = {
            allow-when-locked = true;
          };
        };
        "XF86AudioMute" = {
          spawn = "pamixer -t";
          hyprlandArgs = {
            locked = true;
          };
          niriArgs = {
            allow-when-locked = true;
          };
        };
      };
    };
}
