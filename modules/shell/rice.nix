{
  inputs,
  pkgs,
  system,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      asciiquarium
      cbonsai
      cmatrix
      fastfetch
      nitch
      pipes-rs
      scope-tui
      tenki
      terminal-colors
      inputs.wfetch.packages.${system}.default
    ];

    shellAliases = {
      neofetch = "fastfetch --config neofetch";
      wwfetch = "wfetch --wallpaper";
    };
  };
}
