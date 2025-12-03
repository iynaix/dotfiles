{
  flake.nixosModules.amdgpu =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rocmPackages.rocm-smi
        rocmPackages.rocminfo
      ];
    };
}
