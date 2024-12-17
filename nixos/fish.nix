{ pkgs, user, ... }:
{
  programs.fish.enable = true;
  users.users.${user}.shell = pkgs.fish;
}
