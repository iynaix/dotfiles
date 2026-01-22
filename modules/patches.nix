{
  # patches to be applied to nixpkgs
  flake.patches = [
    # ly 1.3.0 -> 1.3.1
    {
      url = "https://github.com/NixOS/nixpkgs/commit/f0cdc1d033fff25dd1eabc9ff3990564ba1d7414.patch";
      hash = "sha256-/ANLT+IO3lxGhQLuEQ0DQl/7VZWxT2y2ZgwdBfNIY6w=";
    }
    # revert librewolf-unwrapped: 146.0.1-1 -> 147.0-1
    # {
    #   url = "https://github.com/NixOS/nixpkgs/pull/479861/commits/df8a9fb0bd2e91d0ee6a8dddcea9b558322dc575.patch";
    #   hash = "sha256-rovLX1DcOUVtMSXiavIKEWuMDF+NnGfLh7NzAzs7mP4=";
    #   revert = true;
    # }
  ];
}
