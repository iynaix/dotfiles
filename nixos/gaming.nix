{
  inputs,
  ...
}:
{
  # "imports cannot be conditional...if you havent encountered infinite recursion yet, you will soon" - Grandmaster Lin Xianyi
  imports = [
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
  ];
}
