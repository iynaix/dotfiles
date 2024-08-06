_: {
  home.shellAliases = {
    z = "zoxide query -i";
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };
}
