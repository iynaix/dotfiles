_: {
  environment.shellAliases = {
    z = "zoxide query -i";
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    flags = [ "--cmd cd" ];
  };
}
