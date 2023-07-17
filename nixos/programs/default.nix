{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./brave.nix
    ./docker.nix
    ./firefox.nix
    ./gparted.nix
    # ./helix.nix
    ./pathofbuilding
    ./imv.nix
    ./keyring.nix
    ./kitty.nix
    ./nemo.nix
    ./nixlang.nix
    ./virt-manager.nix
    ./vscode.nix
    ./wezterm.nix
    ./zathura.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        libreoffice
        libnotify
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];

    nixpkgs.overlays = [
      (self: super: {
        # creating an overlay for buildRustPackage overlay
        # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
        wallust = super.wallust.overrideAttrs (oldAttrs: rec {
          src = pkgs.fetchgit {
            url = "https://codeberg.org/explosion-mental/wallust.git";
            rev = "c085b41968c7ea7c08f0382080340c6e1356e5fa";
            sha256 = "sha256-np03F4XxGFjWfxCKUUIm7Xlp1y9yjzkeb7F2I7dYttA=";
          };

          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = src + "/Cargo.lock";
            allowBuiltinFetchGit = true;
          };
        });
      })
    ];
  };
}
