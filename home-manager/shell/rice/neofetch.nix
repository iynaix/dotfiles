{
  pkgs,
  user,
  ...
}: let
  waifufetch = pkgs.writeShellScriptBin "waifufetch" ''
    ${pkgs.python3}/bin/python3 ${./waifufetch.py}
  '';
in {
  imports = [./cava.nix];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        neofetch
        waifufetch
      ];

      programs.zsh.shellAliases = {
        neofetch = "neofetch --config ${./neofetch.conf}";
      };
    };
  };
}
