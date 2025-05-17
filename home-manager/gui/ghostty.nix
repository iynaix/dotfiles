{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    ;
  cfg = config.custom.ghostty;
  isGhosttyDefault = config.custom.terminal.package == config.programs.ghostty.package;
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
      desktop = "com.mitchellh.ghostty.desktop";
      exec = mkIf isGhosttyDefault "${getExe config.programs.ghostty.package} -e";
    };

    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      settings = {
        alpha-blending = "linear-corrected";
        background-opacity = terminal.opacity;
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
