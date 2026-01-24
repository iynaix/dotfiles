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
    # orca-slicer 2.3.2-dev
    # https://github.com/NixOS/nixpkgs/pull/480799
    {
      url = "https://github.com/NixOS/nixpkgs/commit/6c08970e09a1f7de80bbdc165c7f9afb8306c027.patch";
      hash = "sha256-gDow7JMMrNgqkRDZVPL9dgPAZCghd4GWI7GBHeteEDo=";
    }
  ];
}
