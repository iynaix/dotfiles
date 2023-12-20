{lib, ...}: {
  imports = [../vm/default.nix];

  # hyprland works within a VM on AMD iGPU wtih hardware acceleration enabled
  iynaix-nixos = lib.mkForce {
    hyprland.enable = true;
  };
}
