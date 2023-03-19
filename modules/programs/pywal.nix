{ user, ... }:
{
  config = {
    home-manager.users.${user} = {
      programs.pywal.enable = true;
    };
  };
}
