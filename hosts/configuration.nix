{
  pkgs,
  user,
  host,
  config,
  ...
}: {
  # handle desktop / window manager
  imports = [
    ../modules/nixos
    ../nixos
  ];

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
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {...}: {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = ["networkmanager" "wheel"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    variables = {
      TERMINAL = config.home-manager.users.${user}.iynaix.terminal.exec;
      EDITOR = "nvim";
      VISUAL = "nvim";
      NIXPKGS_ALLOW_UNFREE = "1";
    };
    systemPackages = with pkgs; [
      curl
      exa
      killall
      neovim
      ntfs3g
      procps
      ripgrep
      tree # for root, normal user has an exa alias
      wget
    ];
  };

  # enable sysrq in case for kernel panic
  boot.kernel.sysctl."kernel.sysrq" = 1;

  # bye bye nano
  environment.defaultPackages = [pkgs.perl pkgs.rsync pkgs.strace];

  # bye bye xterm
  services.xserver.excludePackages = [pkgs.xterm];

  # enable opengl
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  # fuck it, stop bothering me
  systemd.tmpfiles.rules = [
    "L+ /bin/bash                 - - - - /bin/sh"
  ];

  # do not change this value
  system.stateVersion = "23.05";

  # setup fonts
  fonts.packages = config.home-manager.users.${user}.iynaix.fonts.packages;
}
