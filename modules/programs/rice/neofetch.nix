{
  pkgs,
  user,
  config,
  ...
}: {
  imports = [./cava.nix];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        neofetch
      ];

      programs.zsh.shellAliases = {
        neofetch = "neofetch --config ${./neofetch.conf}";
        waifufetch = "neofetch --${
          if config.iynaix.terminal.package == pkgs.kitty
          then "kitty"
          else "sixel"
        } ${./nixos.png} --config ${./neofetch.conf}";
      };
    };
  };
}
