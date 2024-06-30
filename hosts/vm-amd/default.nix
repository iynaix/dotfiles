{ lib, ... }:
{
  imports = [ ../vm/default.nix ];
  custom = {
    plasma.enable = lib.mkForce false;
  };
}
