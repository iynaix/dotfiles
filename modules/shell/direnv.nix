{
  pkgs,
  user,
  lib,
  config,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
