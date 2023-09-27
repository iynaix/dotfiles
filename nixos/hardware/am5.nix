{
  lib,
  config,
  ...
}: let
  cfg = config.iynaix-nixos.am5;
in {
  config = lib.mkIf cfg.enable {
    # fix intel i225-v ethernet dying due to power management
    # https://reddit.com/r/buildapc/comments/xypn1m/network_card_intel_ethernet_controller_i225v_igc/
    # boot.kernelParams = ["pcie_port_pm=off" "pcie_aspm.policy=performance"];

    # by-id doesn't seem to work with amd mobo
    boot.zfs.devNodes = "/dev/disk/by-partuuid";

    # fix clock to be compatible with windows
    time.hardwareClockInLocalTime = true;
  };
}
