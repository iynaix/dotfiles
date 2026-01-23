{
  # patches to be applied to nixpkgs
  flake.patches = [
    # use unstable ly to fix incorrect session being selected
    # https://codeberg.org/fairyglade/ly/issues/911
    {
      url = "https://github.com/NixOS/nixpkgs/commit/b07a099e213a916200722457f6d49d7e2736d9c0.patch";
      hash = "sha256-Ilsel16dblyGxum27ihUCJW9fT9VSrPwrC8oEf/AY7o=";
    }
    # autologin support for ly module
    # https://github.com/NixOS/nixpkgs/pull/473013
    {
      url = "https://github.com/NixOS/nixpkgs/pull/473013/commits/e60ab309b46f2a9e8d93bb0465db469856a786bb.patch";
      hash = "sha256-BEHv3ToUqjFqW2JJti5/TjPJEEVTn4B1hK58zycfezI=";
    }
    # revert librewolf-unwrapped: 146.0.1-1 -> 147.0-1
    # {
    #   url = "https://github.com/NixOS/nixpkgs/pull/479861/commits/df8a9fb0bd2e91d0ee6a8dddcea9b558322dc575.patch";
    #   hash = "sha256-rovLX1DcOUVtMSXiavIKEWuMDF+NnGfLh7NzAzs7mP4=";
    #   revert = true;
    # }
  ];
}
