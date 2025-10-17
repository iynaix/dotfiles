{
  flake.modules.nixos.host-xps =
    { lib, inputs, ... }:
    # manually use config from nixos-hardware as broadcom-sta is marked as insecure
    # copied from https://github.com/NixOS/nixos-hardware/blob/master/dell/xps/13-9343/default.nix
    # omitting broadcom-sta
    {
      imports = [
        "${inputs.nixos-hardware}/common/cpu/intel"
        "${inputs.nixos-hardware}/common/pc/laptop"
        "${inputs.nixos-hardware}/common/pc/ssd"
      ];

      # manually use config from nixos-hardware as broadcom-sta is marked as insecure
      # nixos-hard
      services = {
        fwupd.enable = lib.mkDefault true;
        thermald.enable = lib.mkDefault true;
      };

      boot = {
        # needs to be explicitly loaded or else bluetooth/wifi won't work
        kernelModules = [ "kvm-intel" ];
      };
    };
}
