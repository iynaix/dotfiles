{pkgs, ...}: let
  waifufetch = pkgs.writeShellScriptBin "waifufetch" ''
    ${pkgs.python3}/bin/python3 ${./waifufetch.py} "$@"
  '';
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
    waifufetch
  ];

  home.shellAliases = {
    neofetch = "neofetch --config ${./neofetch.conf}";
  };
}
