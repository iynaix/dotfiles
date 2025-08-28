{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    assertMsg
    mkEnableOption
    mkIf
    versionOlder
    ;
  cfg = config.custom.ghostty;
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

    programs.ghostty =
      let
        padding = 12;
      in
      {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        settings = {
          alpha-blending = "linear-corrected";
          background-opacity =
            0.85
            # more opaque on niri as there is no blur
            + (if (config.custom.wm == "niri" && !config.custom.niri.blur.enable) then 0.1 else 0);
          confirm-close-surface = false;
          copy-on-select = "clipboard";
          # disable clipboard copy notifications temporarily until fixed upstream
          # https://github.com/ghostty-org/ghostty/issues/4800#issuecomment-2685774252
          app-notifications =
            assert (
              assertMsg (versionOlder config.programs.ghostty.package.version "1.2.0") "ghostty: re-enable clipboard copy notifications"
            );
            "no-clipboard-copy";
          cursor-style = "bar";
          font-family = config.custom.fonts.monospace;
          font-feature = "zero";
          font-size = 10;
          font-style = "Medium";
          window-decoration = false;
          window-padding-x = padding;
          window-padding-y = padding;
        };
      };
  };
}
