{ config, pkgs, ... }:

{
  imports = [ ../modules ];

  home = {
    username = "iynaix";
    homeDirectory = "/home/iynaix";

    packages = with pkgs; [
      cinnamon.nemo
      neofetch
    ];

    # gtk = {
    #   enable = true;
    #   theme = {
    #     name = "Catppuccin-Mocha";
    #     package = pkgs.catppuccin-gtk;
    #   };
    # };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "22.11";
  };

  # Let Home Manager install and manage itself.
  programs = { 
    home-manager.enable = true; 

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
    };
  };
}
