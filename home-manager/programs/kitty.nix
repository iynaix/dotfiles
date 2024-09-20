{
  config,
  isNixOS,
  lib,
  ...
}:
let
  cfg = config.custom.kitty;
  inherit (config.custom) terminal;
in
{
  options.custom = with lib; {
    kitty.enable = mkEnableOption "kitty" // {
      default = isNixOS;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      theme = "Catppuccin-Mocha";
      font = {
        name = terminal.font;
        inherit (terminal) size;
      };
      settings = {
        enable_audio_bell = false;
        copy_on_select = "clipboard";
        scrollback_lines = 10000;
        update_check_interval = 0;
        window_margin_width = terminal.padding;
        single_window_margin_width = terminal.padding;
        tab_bar_edge = "top";
        background_opacity = terminal.opacity;
        confirm_os_window_close = 0;
      };
      extraConfig = lib.mkIf (lib.hasPrefix "Maple Mono" terminal.font) ''
        font_features MapleMono-NF-Regular +zero
        font_features MapleMono-NF-Bold +zero
        font_features MapleMono-NF-Italic +zero
        font_features MapleMono-NF-BoldItalic +zero
      '';
    };

    home.shellAliases = {
      # change color on ssh
      ssh = "kitten ssh --kitten=color_scheme=Dracula";
    };
  };
}
