{
  # patches to be applied to nixpkgs
  flake.patches = [
    # use unstable ly to fix incorrect session being selected
    # https://codeberg.org/fairyglade/ly/issues/911
    {
      url = "https://github.com/NixOS/nixpkgs/commit/7c7c50758f95b2df0d897db84a0ac879f2499d82.patch";
      hash = "sha256-yQkTFCPuF27zmYaz8vECGxDXH/xLZfPcPqQBIyAursM=";
    }
    # orca-slicer 2.3.2-dev
    # https://github.com/NixOS/nixpkgs/pull/480799
    {
      url = "https://github.com/NixOS/nixpkgs/commit/6c08970e09a1f7de80bbdc165c7f9afb8306c027.patch";
      hash = "sha256-gDow7JMMrNgqkRDZVPL9dgPAZCghd4GWI7GBHeteEDo=";
    }
    # yt-dlp: 2025.12.08 -> 2025.01.29
    # https://github.com/NixOS/nixpkgs/pull/485127
    {
      url = "https://github.com/NixOS/nixpkgs/compare/32062d4c3937fe4e2c77c1ee96fba7458c6dd7f1%5E..ad5a7a5f67adb9c63300409bc935b52bc35947b0.patch";
      hash = "sha256-dAXsH97qldtwfkwJ9/N/xnNxmdYcYz0cgtbM7e1jXpE=";
    }
  ];
}
