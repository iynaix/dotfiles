{
  enabled = true;
  tags = [ "gui" ];

  config =
    { pkgs, user, ... }:
    {
      environment.systemPackages = [ pkgs.zed-editor ];

      # create directory for trash
      systemd.tmpfiles.rules = [
        "D /persist/.Trash-1000 0700 ${user} users -"
      ];

      custom.persist = {
        home.directories = [
          ".cache/zed"
          ".config/zed"
          ".local/share/zed"
        ];
      };
    };
}
