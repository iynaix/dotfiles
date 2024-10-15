{
  inputs,
  pkgs,
  ...
}:
{
  config = {
    home.packages = [
      inputs.tuido.packages.${pkgs.system}.default # tui todo utility that Oglo wrote
    ];
    custom.persist.home.directories = [
      ".config/tuido"
      ".config/utodo"
    ];
  };
}
