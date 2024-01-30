{
  inputs,
  isNixOS,
  lib,
  self,
  system,
  user,
  ...
}: let
  mkHost = host: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    extraSpecialArgs = {
      inherit self inputs isNixOS host user;
      isLaptop = host == "xps" || host == "framework";
    };
    homeManagerImports = [
      inputs.nix-index-database.hmModules.nix-index
      inputs.nixvim.homeManagerModules.nixvim
      ./${host}/home.nix # host specific home-manager configuration
      ../home-manager
      ../modules/home-manager
    ];
  in
    if isNixOS
    then
      lib.nixosSystem {
        specialArgs = extraSpecialArgs;
        inherit pkgs;

        modules = [
          ./${host} # host specific configuration
          ./${host}/hardware.nix # host specific hardware configuration
          ../nixos
          ../modules/nixos
          ../overlays
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              inherit extraSpecialArgs;

              users.${user} = {
                imports = homeManagerImports ++ [inputs.impermanence.nixosModules.home-manager.impermanence];
              };
            };
          }
          # alias for home-manager
          (lib.mkAliasOptionModule ["hm"] ["home-manager" "users" user])
          inputs.impermanence.nixosModules.impermanence
          inputs.sops-nix.nixosModules.sops
        ];
      }
    else
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit extraSpecialArgs pkgs;

        modules = homeManagerImports ++ [../overlays];
      };
  all_hosts = lib.listToAttrs (map (host: {
    name =
      if isNixOS
      then host
      else "${user}@${host}";
    value = mkHost host;
  }) ["desktop" "framework" "xps" "vm"]);
in
  all_hosts
  // {
    vm-amd = all_hosts.vm // {config.custom-nixos.hyprland.enable = true;};
  }
