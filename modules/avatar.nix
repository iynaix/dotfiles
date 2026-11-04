{
  tags = [ "gui" ];

  config =
    { user, ... }:
    {
      services.accounts-daemon.enable = true;

      # setup user avatar
      systemd.tmpfiles.rules = [
        "f+ /var/lib/AccountsService/users/${user} 0600 root root - [User]\\nIcon=${./avatar.png}\\n"
      ];
    };
}
