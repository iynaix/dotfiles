{
  config,
  lib,
  ...
}: {
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    settings = {
      manager = {
        ratio = [0 1 1];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        linemode = "size";
        show_hidden = true;
      };
    };

    theme = {
      manager = {
        preview_hovered = {underline = false;};
        folder_offset = [1 0 1 0];
        preview_offset = [1 1 1 1];
      };

      status.separator_style = {
        fg = "red";
        bg = "red";
      };
    };

    keymap = {
      # add keymaps for shortcuts
      input.prepend_keymap = lib.flatten (lib.mapAttrsToList (keys: loc: [
          # cd
          {
            on = ["g"] ++ lib.stringToCharacters keys;
            exec = "cd ${loc}";
            desc = "cd to ${loc}";
          }
          # new tab
          {
            on = ["t"] ++ lib.stringToCharacters keys;
            exec = "tab_create ${loc}";
            desc = "open new tab to ${loc}";
          }
          # mv
          {
            on = ["m"] ++ lib.stringToCharacters keys;
            exec = ["yank --cut" "escape --visual --select" loc];
            desc = "move selection to ${loc}";
          }
          # cp
          {
            on = ["Y"] ++ lib.stringToCharacters keys;
            exec = ["yank" "escape --visual --select" loc];
            desc = "copy selection to ${loc}";
          }
        ])
        config.custom.shortcuts);
    };
  };

  home.shellAliases = {
    lf = "yazi";
    y = "yazi";
  };
}
