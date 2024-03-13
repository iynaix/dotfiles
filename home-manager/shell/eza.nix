_: {
  home.shellAliases = {
    t = "eza -la --git-ignore --icons --tree --hyperlink --level 3";
    tree = "eza -la --git-ignore --icons --tree --hyperlink --level 3";
  };

  programs.eza = {
    enable = true;
    icons = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--octal-permissions"
      "--hyperlink"
    ];
  };
}
