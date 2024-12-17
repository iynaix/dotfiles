{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./languages.nix
    ./themes
  ];
  options.custom = with lib; {
    helix.enable = mkEnableOption "helix";
  };
  config = lib.mkIf config.custom.helix.enable {
    home.packages = with pkgs; [
      lldb_18
    ];
    programs.helix = {
      enable = true;
      defaultEditor = false;
      # I'm tired of compiling rust to write rust...
      package = inputs.helix.packages.${pkgs.system}.default;
      # package = pkgs.helix;
      settings = {
        theme = "catppuccin-mocha";
        editor = {
          line-number = "relative";
          idle-timeout = 0;
          auto-format = true;
          auto-completion = true;
          mouse = false;
          statusline = {
            mode = {
              normal = "NORMAL";
              insert = "INSERT";
              select = "SELECT";
            };
            left = [
              "mode"
              # "separator"
              "spinner"
              "file-name"
            ];
            center = [ ];
            right = [
              "diagnostics"
              "selections"
              "position"
              "file-encoding"
            ];
            separator = "|";
          };
          inline-diagnostics = {
            cursor-line = "warning";
            other-lines = "disable";
            prefix-len = 5;
            max-diagnostics = 10;
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          indent-guides = {
            render = true;
            character = "|"; # Some characters that work well: "▏", "┆", "┊", "⸽"
            skip-levels = 1;
          };
          whitespace = {
            render = {
              space = "none";
              tab = "none";
              nbsp = "none";
              newline = "none";
            };
            characters = {
              space = "·";
              nbsp = "⍽";
              nnbsp = "␣";
              tab = "→";
              newline = "⏎";
              tabpad = "·";
            };
          };
          lsp = {
            snippets = true;
            display-messages = true;
            display-inlay-hints = true;
          };
          file-picker = {
            hidden = true;
          };
        };
      };
    };
  };
}
