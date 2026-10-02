{
  packages =
    { pkgs, ... }:
    let
      drv =
        {
          git,
          nh,
          lib,
          stdenvNoCC,
          makeWrapper,
          # variables
          dots ? "$HOME/projects/dotfiles",
          name ? "nsw",
          host ? "desktop",
          specialisation ? "",
        }:
        stdenvNoCC.mkDerivation {
          name = "${name}-${specialisation}";
          version = "1.0";

          src = ./.;

          nativeBuildInputs = [ makeWrapper ];

          postPatch = /* sh */ ''
            substituteInPlace nsw.sh \
              --replace-fail "@dots@" "${dots}" \
              --replace-fail "@host@" "${host}" \
              --replace-fail "@specialisation@" "${specialisation}"
          '';

          postInstall = /* sh */ ''
            install -D ./nsw.sh $out/bin/nsw

            wrapProgram $out/bin/nsw \
              --prefix PATH : ${
                lib.makeBinPath [
                  git
                  nh
                ]
              }
          '';

          meta = {
            description = "nh wrapper";
            license = lib.licenses.mit;
            platforms = lib.platforms.linux;
          };
        };
    in
    {
      nsw = pkgs.callPackage drv { };
    };

  config =
    {
      config,
      host,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      dots = "/persist/home/${user}/projects/dotfiles";

      # nixos-rebuild switch, use different package for home-manager standalone
      nsw = pkgs.custom.nsw.override {
        name = "nsw";
        inherit dots host;
        # specialisation = config.custom.specialisation.current;
      };
      # nixos-rebuild build
      nsb = pkgs.writeShellApplication {
        name = "nsb";
        runtimeInputs = [ nsw ];
        text = /* sh */ ''nsw build "$@"'';
      };
      # nixos-rebuild test
      nst = pkgs.writeShellApplication {
        name = "nst";
        runtimeInputs = [
          (nsw.override {
            specialisation = config.custom.specialisation.current;
          })
        ];
        text = /* sh */ ''nsw test "$@"'';
      };
      # nixos-rebuild boot
      nsbt = pkgs.writeShellApplication {
        name = "nsbt";
        runtimeInputs = [ nsw ];
        text = /* sh */ ''nsw boot "$@"'';
      };
      # update via nix flake
      upd8 = pkgs.writeShellApplication {
        name = "upd8";
        runtimeInputs = [
          config.programs.tack.package
          nsw
        ];
        text = /* sh */ ''
          pushd ${dots} > /dev/null
          tack update
          nsw "$@"
          popd > /dev/null
        '';
      };
      # build and push config for laptop
      nsw-remote = pkgs.writeShellApplication {
        name = "nsw-remote";
        text = /* sh */ ''
          if [ -z "$1" ] || [ -z "$2" ]; then
              echo "Error: Missing required arguments."
              echo "Usage: $0 HOST_IP FLAKE_HOST"
              exit 1
          fi

          pushd ${dots} > /dev/null
          nixos-rebuild switch --target-host "root@$1" --flake ".#$2"
          popd > /dev/null
        '';
      };
    in
    {
      environment.systemPackages = [
        nsbt
        nsb
        nsw
        nst
        upd8
      ]
      ++ lib.optionals (host == "desktop") [ nsw-remote ];
    };
}
