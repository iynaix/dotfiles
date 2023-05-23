{
  user,
  pkgs,
  ...
}: {
  config = {
    systemPackages = [pkgs.helix];

    home-manager.users.${user} = {
      programs.helix = {
        enable = true;
        settings = {
          theme = "catppuccin_mocha";
        };
      };
    };
  };
}
