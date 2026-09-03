{
  outputs =
    { self, ... }@args:
    let
      inputs = import ./inputs-patched.nix args;
      inherit (inputs.nixpkgs) lib;

      flakeLib = import ./flake-lib.nix { inherit inputs lib self; };
      inherit (flakeLib) mkHost mkPackages;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # provide package for each system
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f (
            import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );

      mkHostInfo = tags: {
        inherit tags;
        modules = [ ./modules ];
        specialArgs = {
          inherit inputs self;
          libCustom = import ./lib.nix { inherit lib; };
          user = "iynaix";
        };
        validTags = [
          "gui"
          "wm"
          "laptop"
          "vm"
        ];
      };

      # add tags to a hostInfo
      addTags = info: extraTags: (info // { tags = (info.tags or [ ]) ++ extraTags; });

      hostInfo = {
        desktop = mkHostInfo [
          "gui"
          "wm"
        ];

        framework = mkHostInfo [
          "gui"
          "wm"
          "laptop"
        ];

        xps = mkHostInfo [
          "gui"
          "wm"
          "laptop"
        ];
      };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop" hostInfo.desktop;
        framework = mkHost "framework" hostInfo.framework;
        xps = mkHost "xps" hostInfo.xps;

        vm = mkHost "vm" (mkHostInfo [
          "gui"
          "vm"
        ]);

        vm-wm = mkHost "vm" (mkHostInfo [
          "gui"
          "wm"
          "vm"
        ]);

        # vm versions of main hosts
        desktop-vm = mkHost "desktop" (addTags hostInfo.desktop [ "vm" ]);
        framework-vm = mkHost "framework" (addTags hostInfo.framework [ "vm" ]);
        xps-vm = mkHost "xps" (addTags hostInfo.xps [ "vm" ]);
      }
      # build with nbuild-iso
      // (import ./isos.nix { inherit inputs lib self; });

      devShells = forAllSystems (pkgs: {
        default = import ./devshell.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rs);

      packages = forAllSystems (
        pkgs:
        mkPackages pkgs [ ./modules ] {
          inherit
            inputs
            lib
            self
            ;
          libCustom = import ./lib.nix { inherit lib pkgs; };
        }
      );
    };
}
