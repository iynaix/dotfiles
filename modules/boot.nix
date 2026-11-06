{
  config =
    { lib, ... }:
    {
      boot = {
        # always allow booting from usb
        initrd.availableKernelModules = [ "uas" ];
        loader = {
          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
          };
          timeout = 3;

          limine = {
            enable = true;
            # hide the ugly semi-transparent box
            extraConfig = ''
              term_background: FF000000
              term_background_bright: FF000000
            '';
          };
        };
        supportedFilesystems.ntfs = true;
      };

      # faster boot times
      systemd.services.NetworkManager-wait-online.wantedBy = lib.mkForce [ ];

      # reduce journald logs
      services.journald.settings.Journal.SystemMaxUse = "50M";
    };
}
