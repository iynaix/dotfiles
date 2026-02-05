{
  inputs,
  lib,
  self,
  withSystem,
  ...
}:
{
  flake = {
    overlays = {
      # add flake.packages as pkgs.custom
      pkgsCustom = _: prev: {
        custom = withSystem prev.stdenv.hostPlatform.system ({ config, ... }: config.packages);
      };

      # access to nixpkgs-stable
      nixpkgsStable = _: prev: {
        stable = import inputs.nixpkgs-stable {
          inherit (prev.pkgs.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      };

      # misc patches to packages in pkgs
      pkgsPatches = _: prev: {
        # nixos-small logo looks like ass
        fastfetch = prev.fastfetch.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [ ./fastfetch-nixos-old-small.patch ];
        });

        # add default font to silence null font errors
        lsix = prev.lsix.overrideAttrs (o: {
          postFixup = /* sh */ ''
            substituteInPlace $out/bin/lsix \
              --replace-fail '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
            ${o.postFixup}
          '';
        });

        # fix nix package count for nitch
        nitch = prev.nitch.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [ ./nitch-nix-pkgs-count.patch ];
        });

        # fix some ugly styling for nemo in tokyonight
        tokyonight-gtk-theme = prev.tokyonight-gtk-theme.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [ ./tokyonight-style.patch ];
        });
      };

      # writeShellApplication with support for completions
      writeShellApplicationCompletions = _: prev: {
        custom = (prev.custom or { }) // {
          writeShellApplicationCompletions =
            {
              name,
              completions ? { },
              ...
            }@shellArgs:
            let
              inherit (prev) writeShellApplication writeText installShellFiles;
              # get the needed arguments for writeShellApplication
              app = writeShellApplication (lib.intersectAttrs (lib.functionArgs writeShellApplication) shellArgs);
              completionsStr = lib.concatMapAttrsStringSep " " (
                shell: content:
                lib.optionalString (builtins.elem shell [
                  "bash"
                  "zsh"
                  "fish"
                  "nushell"
                ]) "--${shell} ${writeText "${shell}-completion" content}"
              ) completions;
            in
            if completions == { } then
              app
            else
              app.overrideAttrs (o: {
                nativeBuildInputs = (o.nativeBuildInputs or [ ]) ++ [ installShellFiles ];

                buildCommand = o.buildCommand + ''
                  installShellCompletion --cmd ${name} ${completionsStr}
                '';
              });
        };
      };
    };

    nixosModules.core = _: {
      nixpkgs.overlays = [
        self.overlays.pkgsCustom
        self.overlays.nixpkgsStable
        self.overlays.pkgsPatches
        self.overlays.writeShellApplicationCompletions
      ];
    };
  };
}
