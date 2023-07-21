{pkgs, ...}: let
  waifufetch = pkgs.writeShellScriptBin "waifufetch" ''
    ${pkgs.python3}/bin/python3 ${./waifufetch.py}
  '';
in {
  home.packages = with pkgs; [
    neofetch
    waifufetch
  ];

  programs.zsh.shellAliases = {
    neofetch = "neofetch --config ${./neofetch.conf}";
    neochallenge = "neofetch --config ${./neofetch-challenge.conf}";
  };
}
