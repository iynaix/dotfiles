{
  config,
  isNixOS,
  lib,
  ...
}:
let
  inherit (lib) hasPrefix mkEnableOption mkIf;
  cfg = config.custom.kitty;
  inherit (config.custom) terminal;
in
{
  options.custom = {
    kitty.enable = mkEnableOption "kitty" // {
      default = isNixOS && !config.custom.headless;
    };
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      themeFile = "Catppuccin-Mocha";
      font = {
        name = terminal.font;
        inherit (terminal) size;
      };
      settings = {
        enable_audio_bell = false;
        copy_on_select = "clipboard";
        cursor_trail = 1;
        cursor_trail_start_threshold = 10;
        scrollback_lines = 10000;
        update_check_interval = 0;
        window_padding_width = terminal.padding;
        tab_bar_edge = "top";
        background_opacity = terminal.opacity;
        confirm_os_window_close = 0;
        # for removing kitty padding when in neovim
        allow_remote_control = "password";
        remote_control_password = ''"" set-spacing''; # only allow setting of padding
        listen_on = "unix:/tmp/kitty-socket";
      };
      extraConfig = mkIf (hasPrefix "JetBrains" terminal.font) ''
        font_features JetBrainsMonoNF-Regular +zero
        font_features JetBrainsMonoNF-Bold +zero
        font_features JetBrainsMonoNF-Italic +zero
        font_features JetBrainsMonoNF-BoldItalic +zero
      '';
    };

    home.shellAliases = {
      # change color on ssh
      ssh = "kitten ssh --kitten=color_scheme=Dracula";
    };

    # remove padding while in neovim
    # programs.nixvim.extraConfigLua = ''
    #   vim.api.nvim_create_autocmd("VimEnter", {
    #     callback = function()
    #       if vim.env.TERM == "xterm-kitty" then
    #         vim.fn.system(string.format('kitty @ --to %s set-spacing padding=0', vim.env.KITTY_LISTEN_ON))
    #       end
    #     end
    #   })

    #   vim.api.nvim_create_autocmd("VimLeave", {
    #     callback = function()
    #       if vim.env.TERM == "xterm-kitty" then
    #         vim.fn.system(string.format('kitty @ --to %s set-spacing padding=${toString terminal.padding}', vim.env.KITTY_LISTEN_ON))
    #       end
    #     end
    #   })
    # '';
  };
}
