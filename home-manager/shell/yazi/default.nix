{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    settings = {
      manager = {
        layout = [0 1 1];
        sort_by = "alphabetical";
        sort_sensitive = false;
        linemode = "size";
        show_hidden = true;
      };
    };
  };

  # add keymaps for shortcuts
  # yazi doesn't add keymaps but requires adding to the original keymap.toml
  xdg.configFile = {
    "yazi/keymap.toml".source = pkgs.substituteAll {
      src = ./keymap.toml;

      extra_keymaps = lib.pipe config.iynaix.shortcuts [
        (lib.mapAttrsToList (name: value: let
          keys = lib.stringToCharacters name;
          toArr = arr: "[ ${lib.concatStringsSep ", " (map (c: ''"${c}"'') arr)} ]";
        in [
          # cd
          ''{ on = ${toArr (["g"] ++ keys)}, exec = "cd ${value}", desc = "cd to ${value}" }''
          # new tab
          ''{ on = ${toArr (["t"] ++ keys)}, exec = "tab_create ${value}", desc = "open new tab to ${value}" }''
          # mv
          ''{ on = ${toArr (["m"] ++ keys)}, exec = ${toArr ["yank --cut" "escape --visual --select" value]}, desc = "move selection to ${value}" }''
          # cp
          ''{ on = ${toArr (["Y"] ++ keys)}, exec = ${toArr ["yank" "escape --visual --select" value]}, desc = "copy selection to ${value}" }''
        ]))
        lib.flatten
        (lib.concatStringsSep ",\n")
      ];
    };
    "yazi/theme.toml".source = ./theme.toml;
  };

  home.shellAliases = {
    lf = "ya";
    y = "ya";
  };
}
