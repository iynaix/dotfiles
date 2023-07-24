{
  pkgs,
  user,
  host,
  config,
  lib,
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
    shell = pkgs.zsh;
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = user;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    variables = {
      TERMINAL = lib.getExe config.home-manager.users.${user}.iynaix.terminal.package;
      EDITOR = "nvim";
      VISUAL = "nvim";
      NIXPKGS_ALLOW_UNFREE = "1";
    };
    shells = [pkgs.zsh];
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
  programs.zsh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # enable sysrq in case for kernel panic
  boot.kernel.sysctl."kernel.sysrq" = 1;

  # faster shutdown
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=5s
  '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # auto login
  services.xserver.displayManager.autoLogin = {
    enable = true;
    inherit user;
  };

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

  # shut sudo up
  security.sudo.extraConfig = "Defaults lecture=never";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # do not change this value
  system.stateVersion = "23.05";

  # setup fonts
  fonts.fonts = config.home-manager.users.${user}.iynaix.fonts.packages;

  # enable flakes
  nix = {
    settings = {
      auto-optimise-store = true; # Optimise syslinks
      substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    gc = {
      # Automatic garbage collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
    package = pkgs.nixVersions.unstable;
    # use flakes
    extraOptions = "experimental-features = nix-command flakes";
  };
}
