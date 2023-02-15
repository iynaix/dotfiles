{ config, pkgs, lib, ... }:

{
  imports = [ ../modules ];

  home = {
    username = "iynaix";
    homeDirectory = "/home/iynaix";

    packages = with pkgs;
      [
        # stops errors with copilot login?
        gcr
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

  xsession.profileExtra = lib.concatStringsSep "\n" [
    # fix the cursor
    "xsetroot -cursor_name left_ptr"
    # $(gnome-keyring-daemon --start)
    # export SSH_AUTH_SOCK
  ];

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
