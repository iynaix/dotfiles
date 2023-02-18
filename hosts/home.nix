{ config, pkgs, lib, user, ... }:

{
  imports = [ ../modules ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${user} = {
    home = {
      username = user;
      homeDirectory = "/home/${user}";

      packages = with pkgs; [
        # nix dev stuff
        nixfmt
        rnix-lsp
        nixpkgs-fmt
      ];

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
  };
}
