{
  # patches to be applied to nixpkgs
  flake.patches = [
    # use unstable ly to fix incorrect session being selected
    # https://codeberg.org/fairyglade/ly/issues/911
    {
      url = "https://github.com/NixOS/nixpkgs/commit/7c7c50758f95b2df0d897db84a0ac879f2499d82.patch";
      hash = "sha256-yQkTFCPuF27zmYaz8vECGxDXH/xLZfPcPqQBIyAursM=";
    }
    # autologin support for ly module
    # https://github.com/NixOS/nixpkgs/pull/473013
    {
      url = "https://github.com/NixOS/nixpkgs/pull/473013.patch";
      hash = "sha256-eHDeWYamHuzO29Wg4zEEQYaK5XdmH1bi+nRtq+83aYc=";
    }
    # orca-slicer 2.3.2-dev
    # https://github.com/NixOS/nixpkgs/pull/480799
    {
      url = "https://github.com/NixOS/nixpkgs/commit/6c08970e09a1f7de80bbdc165c7f9afb8306c027.patch";
      hash = "sha256-gDow7JMMrNgqkRDZVPL9dgPAZCghd4GWI7GBHeteEDo=";
    }
  ];
}
