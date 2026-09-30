{
  tags = [ "gui" ];

  config =
    { user, ... }:
    {
      services.accounts-daemon.enable = true;

      # setup user avatar
      systemd.tmpfiles.rules = [
        "C /var/lib/AccountsService/icons/${user} 0644 root root - ${./avatar.png}"
        "f+ /var/lib/AccountsService/users/${user} 0600 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${user}\\n"
      ];
    };
}
