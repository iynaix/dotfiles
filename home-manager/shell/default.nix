{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./bash.nix
    ./btop.nix
    ./cava.nix
    ./direnv.nix
    ./eza.nix
    ./fish.nix
    ./git.nix
    ./neovim
    ./nix.nix
    ./rice.nix
    ./rust.nix
    ./shell.nix
    ./starship.nix
    ./tmux.nix
    ./typescript.nix
    ./yazi.nix
  ];

  home.packages =
    with pkgs;
    [
      # dysk # better disk info
      ets # add timestamp to beginning of each line
      fd # better find
      fx # terminal json viewer and processor
      htop
      jq
      sd # better sed
      # grep, with boolean query patterns, e.g. ug --files -e "A" --and "B"
      ugrep
    ]
    # add custom user created shell packages
    ++ (lib.attrValues config.custom.shell.finalPackages);

  # add custom user created shell packages to pkgs.custom.shell
  nixpkgs.overlays = lib.mkIf (!isNixOS) [
    (_: prev: {
      custom = prev.custom // {
        shell = config.custom.shell.finalPackages;
      };
    })
  ];

  programs = {
    bat.enable = true;

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      options = [ "--cmd cd" ];
    };
  };

  custom.persist = {
    home = {
      cache = [ ".local/share/zoxide" ];
    };
  };
}
