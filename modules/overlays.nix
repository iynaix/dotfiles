{
  inputs,
  lib,
  self,
  withSystem,
  ...
}:
{
  flake.overlays = {
    # access to nixpkgs-stable
    nixpkgsStable = _: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (prev.pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    };

    # add flake.packages as pkgs.custom
    pkgsCustom = _: prev: {
      custom = withSystem prev.stdenv.hostPlatform.system ({ config, ... }: config.packages);
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

  flake.modules.nixos.core = _: {
    nixpkgs.overlays = [
      self.overlays.pkgsCustom
      self.overlays.nixpkgsStable
      self.overlays.writeShellApplicationCompletions
    ];
  };
}
