{
  flake.modules.nixos.hardware_amdgpu =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rocmPackages.rocm-smi
        rocmPackages.rocminfo
      ];
    };
}
