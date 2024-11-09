{ lib, pkgs, ... }:
{
  programs = {
    git.ignores = [ ".jj" ];
    jujutsu = {
      enable = true;
      settings = {
        user = {
          email = "pilum-murialis.toge@proton.me";
          name = "Elias Ainsworth";
        };
        ui.pager = "${lib.getExe pkgs.bat} --plain --theme base16";
      };
    };
  };
}
