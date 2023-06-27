{
  pkgs,
  user,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        nil
        # nixd
        alejandra
      ];
    };
  };
}
