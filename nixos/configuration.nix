{
  pkgs,
  user,
  host,
  ...
}: {
  # Bootloader.
  boot.loader = {
    # systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      devices = ["nodev"];
      efiSupport = true;
    };
  };

  networking.hostName = "${user}-${host}"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Singapore";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_SG.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_SG.UTF-8";
    LC_IDENTIFICATION = "en_SG.UTF-8";
    LC_MEASUREMENT = "en_SG.UTF-8";
    LC_MONETARY = "en_SG.UTF-8";
    LC_NAME = "en_SG.UTF-8";
    LC_NUMERIC = "en_SG.UTF-8";
    LC_PAPER = "en_SG.UTF-8";
    LC_TELEPHONE = "en_SG.UTF-8";
    # week starts on a Monday, for fuck's sake
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
    # bye bye xterm
    excludePackages = [pkgs.xterm];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {...}: {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = ["networkmanager" "wheel"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # enable sysrq in case for kernel panic
  boot.kernel.sysctl."kernel.sysrq" = 1;

  # enable opengl
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  # zram
  zramSwap.enable = true;

  # do not change this value
  system.stateVersion = "23.05";
}
