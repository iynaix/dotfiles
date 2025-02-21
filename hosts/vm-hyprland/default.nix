{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  imports = [ ../vm/default.nix ];
  custom = {
    plasma.enable = mkForce false;
  };
}
