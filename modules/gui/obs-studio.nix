{
  flake.modules.nixos.programs_obs-studio = {
    programs.obs-studio.enable = true;

    custom.persist = {
      home.directories = [ ".config/obs-studio" ];
    };
  };
}
