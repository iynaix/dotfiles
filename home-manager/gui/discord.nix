{ inputs, ... }:
{
  imports = [
    inputs.nixcord.homeManagerModules.nixcord
  ];

  programs.nixcord = {
    enable = true; # enable Nixcord. Also installs discord package
    # quickCss = "some CSS"; # quickCSS file
    config = {
      #   useQuickCss = true; # use out quickCSS
      themeLinks = [
        # or use an online theme
        # "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
        # "https://github.com/refact0r/midnight-discord/blob/master/flavors/midnight-catppuccin-mocha.theme.css"
        "https://DiscordStyles.github.io/DarkMatter/src/base.css"
      ];
      frameless = true; # set some Vencord options
      transparent = true;
      plugins = {
        fakeNitro.enable = true;
        moreKaomoji.enable = true;
      };
    };
    # extraConfig = {
    #   # Some extra JSON config here
    #   # ...
    # };
  };

  custom.persist = {
    home.directories = [
      ".config/discord"
      ".config/Discord"
      ".config/Vencord"
    ];
  };

}
