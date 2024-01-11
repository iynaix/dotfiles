# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  swww = {
    pname = "swww";
    version = "0908f36050d545a0eb97ca0cbfc40c47fc50d6ba";
    src = fetchFromGitHub {
      owner = "Horus645";
      repo = "swww";
      rev = "0908f36050d545a0eb97ca0cbfc40c47fc50d6ba";
      fetchSubmodules = false;
      sha256 = "sha256-NRmlctWwiUVlbB457y3e2BpWNyJ7CHpEnAYazwYQZpk=";
    };
    date = "2023-12-21";
  };
  waybar = {
    pname = "waybar";
    version = "748fc809b51a6063e1b39bb17cc2c54e65d6291b";
    src = fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "748fc809b51a6063e1b39bb17cc2c54e65d6291b";
      fetchSubmodules = false;
      sha256 = "sha256-iV8J2ucbxyaVDD6w8VwB329phA8tzGYWYYlM8JLXFq0=";
    };
    date = "2024-01-08";
  };
  wezterm = {
    pname = "wezterm";
    version = "6c36a4dda2527836af0e0aa076d5dd0bd8d3dd79";
    src = fetchFromGitHub {
      owner = "wez";
      repo = "wezterm";
      rev = "6c36a4dda2527836af0e0aa076d5dd0bd8d3dd79";
      fetchSubmodules = true;
      sha256 = "sha256-bWcez8vJlZttrVmBjyXZBZIbSBE7tpu1lkVSH1T6Fw0=";
    };
    date = "2024-01-11";
  };
}
