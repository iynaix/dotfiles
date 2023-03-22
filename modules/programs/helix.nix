{user, ...}: {
  config = {
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
