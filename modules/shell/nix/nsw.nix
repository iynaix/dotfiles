{ lib, ... }:
{
  perSystem =
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
            maintainers = [ lib.maintainers.iynaix ];
            platforms = lib.platforms.linux;
          };
        };
    in
    {
      packages.nsw = pkgs.callPackage drv { };
    };

  flake.nixosModules.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) dots host;
      # nixos-rebuild switch, use different package for home-manager standalone
      nsw = pkgs.custom.nsw.override {
        name = "nsw";
        inherit dots host;
        specialisation = config.custom.specialisation.current;
      };
      # nixos-rebuild boot
      nsbt = pkgs.writeShellApplication {
        name = "nsbt";
        runtimeInputs = [ nsw ];
        text = /* sh */ ''nsw boot "$@"'';
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
          (nsw.override { specialisation = config.custom.specialisation.current; })
        ];
        text = /* sh */ ''nsw test "$@"'';
      };
      # update all nvfetcher overlays and packages
      nv-update = pkgs.writeShellApplication {
        name = "nv-update";
        runtimeInputs = [ pkgs.nvfetcher ];
        text = /* sh */ ''
          pushd ${dots} > /dev/null
          if [ "$#" -eq 0 ]; then
            nvfetcher --keep-old
          else
            nvfetcher --keep-old --filter "$1"
          fi
          popd > /dev/null
        '';
      };
      # update via nix flake
      upd8 = pkgs.writeShellApplication {
        name = "upd8";
        runtimeInputs = [
          pkgs.nvfetcher
          nsw
          nv-update
        ];
        text = /* sh */ ''
          pushd ${dots} > /dev/null
          nix flake update
          nv-update
          nsw "$@"
          popd > /dev/null
        '';
      };
      # build and push config for laptop
      nsw-remote = pkgs.writeShellApplication {
        name = "nsw-remote";
        text = /* sh */ ''
          pushd ${dots} > /dev/null
          nixos-rebuild switch --target-host "root@''${1:-framework}" --flake ".#''${2:-framework}"
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
        nv-update
        upd8
      ]
      ++ lib.optionals (host == "desktop") [ nsw-remote ];
    };
}
