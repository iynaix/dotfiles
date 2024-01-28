{pkgs, ...}: {
  programs = {
    # firefox dev edition
    firefox = {
      enable = true;
      package = pkgs.firefox-devedition-bin;

      # profiles.iynaix = {
      #   # TODO: set as default profile
      #   # isDefault = true;

      #   # TODO: define keyword searches here?
      #   # search.engines = [ ];

      #   extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
      #     bitwarden
      #     darkreader
      #     sponsorblock
      #     ublock-origin
      #   ];
      # };
    };
  };

  custom.persist = {
    home.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
