{ pkgs, user, config, ... }:
{
  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        pkgs.vscode
        # nix dev stuff
        nixfmt
        nil
        nixpkgs-fmt
      ];
    };

    iynaix.persist.home.directories = [
      ".config/Code"
      ".vscode"
    ];
  };
}
