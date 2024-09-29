{ pkgs, inputs, ... }:
{
  imports = [
    ./languages.nix
    ./themes
  ];
  home.packages = [ pkgs.lldb_18 ];
  programs.helix = {
    enable = true;
    # defaultEditor = true;
    package = inputs.helix.packages.${pkgs.system}.helix;
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
            "separator"
            "file-name"
          ];
          center = [ "spinner" ];
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
          character = "▏"; # Some characters that work well: "▏", "┆", "┊", "⸽"
          skip-levels = 1;
        };
        whitespace = {
          render = {
            space = "none";
            tab = "all";
            nbsp = "all";
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
          hidden = false;
        };
      };
    };
  };
}
