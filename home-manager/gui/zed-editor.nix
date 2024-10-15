{ config, pkgs, ... }:
{
  home.packages = [ pkgs.zed-editor ];
  home.file.".config/zed/settings.json" = {
    force = true;
    text = ''
      {
        "vim_mode": true,
        "ui_font_size": 16,
        "buffer_font_size": 14,
        "ui_font_family": "${config.custom.fonts.monospace}",
        "buffer_font_family": "${config.custom.fonts.monospace}",
        "theme": {
          "mode": "system",
          "light": "Catppuccin Mocha (Blur)", // I will kill anyone that tries to use a light scheme
          "dark": "Catppuccin Mocha (Blur)"
        },
        "load_direnv": "shell_hook",
        "lsp": {
          "rust-analyzer": {
            "initialization_options": {
              "inlayHints": {
                "maxLength": null,
                "lifetimeElisionHints": {
                  "enable": "skip_trivial",
                  "useParameterNames": true
                },
                "closureReturnTypeHints": {
                  "enable": "always"
                }
              }
            }
          }
        }
      }
    '';
  };

  custom.persist = {
    home.directories = [
      ".config/zed"
      ".local/share/zed"
    ];
  };
}
