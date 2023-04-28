{
  lib,
  config,
  ...
}: {
  options.iynaix.am5 = {
    enable = lib.mkEnableOption "B650E-E motherboard";
  };

  config = lib.mkIf config.iynaix.am5.enable {
    # fix intel i225-v ethernet dying due to power management
    # https://reddit.com/r/buildapc/comments/xypn1m/network_card_intel_ethernet_controller_i225v_igc/
    boot.kernelParams = ["pcie_port_pm=off" "pcie_aspm.policy=performance"];

    # by-id doesn't seem to work with amd mobo
    boot.zfs.devNodes = "/dev/disk/by-partuuid";
  };
}
