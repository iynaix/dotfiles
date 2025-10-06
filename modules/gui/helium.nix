{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.custom.helium
  ];

  # TODO: policies don't seem to be supported yet
  # environment.etc."net.imput.helium/policies/managed/default.json".text = builtins.toJSON {
  #   ExtensionInstallForcelist = extensions;
  # };

  custom.persist = {
    home.directories = [
      ".cache/net.imput.helium"
      ".config/net.imput.helium"
    ];
  };
}
