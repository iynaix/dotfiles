{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.custom.ghostty;
  inherit (config.custom) terminal;
in
{
  options.custom = {
    ghostty = {
      enable = mkEnableOption "ghostty" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    custom.terminal = {
      app-id = "com.mitchellh.ghostty";
      desktop = "com.mitchellh.ghostty.desktop";
    };

    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      settings = {
        alpha-blending = "linear-corrected";
        background-opacity =
          terminal.opacity
          # more opaque on niri as there is no blur
          + (if (config.custom.wm == "niri" && !config.custom.niri.blur.enable) then 0.1 else 0);
        confirm-close-surface = false;
        copy-on-select = "clipboard";
        # disable clipboard copy notifications temporarily until fixed upstream
        # https://github.com/ghostty-org/ghostty/issues/4800#issuecomment-2685774252
        app-notifications = "no-clipboard-copy";
        cursor-style = "bar";
        font-family = terminal.font;
        font-feature = "zero";
        font-size = terminal.size;
        font-style = "Medium";
        minimum-contrast = 1.1;
        window-decoration = false;
        window-padding-x = terminal.padding;
        window-padding-y = terminal.padding;
      };
    };
  };
}
