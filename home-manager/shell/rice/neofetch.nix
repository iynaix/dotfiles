{
  config,
  pkgs,
  ...
}: let
  waifufetch = pkgs.writeShellScriptBin "waifufetch" ''
    ${pkgs.python3}/bin/python3 ${./waifufetch.py} "$@"
  '';
  neochallenge = pkgs.writeShellApplication {
    name = "neochallenge";
    runtimeInputs = [waifufetch pkgs.neofetch];
    text = ''
      img=$(waifufetch --image)

      neofetch --${
        if config.iynaix.terminal.package == pkgs.kitty
        then "kitty"
        else "sixel"
      } "$img" "$@" --config ${./neofetch-challenge.conf}
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
