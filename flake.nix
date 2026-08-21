{
  description = "iynaix's dotfiles";

  outputs =
    { self, ... }@args:
    let
      inputs = import ./inputs-patched.nix args;
      inherit (inputs.nixpkgs) lib;

      flakeLib = import ./flake-lib.nix { inherit inputs lib self; };
      inherit (flakeLib)
        addTags
        forAllSystems
        mkHost
        mkPackages
        ;

      hostInfo = {
        desktop = {
          system = "x86_64-linux";
          tags = [
            "gui"
            "wm"
          ];
        };

        framework = {
          system = "x86_64-linux";
          tags = [
            "gui"
            "wm"
            "laptop"
          ];
        };

        xps = {
          system = "x86_64-linux";
          tags = [
            "gui"
            "wm"
            "laptop"
          ];
        };
      };
    in
    {
      nixosConfigurations = (
        {
          desktop = mkHost "desktop" hostInfo.desktop;
          framework = mkHost "framework" hostInfo.framework;
          xps = mkHost "xps" hostInfo.xps;

          vm = mkHost "vm" {
            system = "x86_64-linux";
            tags = [
              "gui"
              "vm"
            ];
          };

          vm-wm = mkHost "vm-wm" {
            system = "x86_64-linux";
            tags = [
              "gui"
              "wm"
              "vm"
            ];
          };

          # vm versions of main hosts
          desktop-vm = mkHost "desktop-vm" (addTags hostInfo.desktop [ "vm" ]);
          framework-vm = mkHost "framework-vm" (addTags hostInfo.framework [ "vm" ]);
          xps-vm = mkHost "xps-vm" (addTags hostInfo.xps [ "vm" ]);
        }
        # build with nbuild-iso
        // (import ./isos.nix { inherit inputs lib self; })
      );

      devShells = forAllSystems (pkgs: {
        default = import ./devshell.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rs);

      packages = forAllSystems mkPackages;
    };
}
