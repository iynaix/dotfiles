{pkgs, ...}: let
  neochallenge = pkgs.writeShellApplication {
    name = "neochallenge";
    runtimeInputs = [pkgs.neofetch];
    text = ''
      neofetch --config ${./neofetch-challenge.conf}
    '';
  };
in {
  home.packages = with pkgs; [
    neofetch
    neochallenge
  ];

  home.shellAliases = {
    neofetch = "neofetch --config ${./neofetch.conf}";
  };
}
