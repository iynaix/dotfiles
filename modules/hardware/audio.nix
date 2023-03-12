{ pkgs, host, user, config, ... }:
{
  # setup pipewire for audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    alsa-utils
    pamixer
    pavucontrol
  ];

  home-manager.users.${user} = {
    services = {
      sxhkd.keybindings =
        let
          volume-change = pkgs.writeShellScriptBin "volume-change" /* sh */ ''
            # arbitrary but unique message id
            msgId="906881"

            # change the volume using alsa
            amixer set Master "$@" > /dev/null

            # query amixer for the current volume and whether or not the speaker is muted
            volume="$(amixer get Master | tail -1 | awk '{print $5}' | sed 's/[^0-9]*//g')"
            mute="$(amixer get Master | tail -1 | awk '{print $6}' | sed 's/[^a-z]*//g')"

            if [[ $volume == 0 || "$mute" == "off" ]]; then
                # show sound muted notification
                dunstify -a "volume-change" -u low -r "$msgId" "Volume: Muted"
            else
                # show volume notification
                dunstify -a "volume-change" -u low -r "$msgId" "Volume: ''${volume}%"
            fi
          '';
        in
        {
          "XF86AudioLowerVolume" = "${volume-change}/bin/volume-change 5%-";
          "XF86AudioRaiseVolume" = "${volume-change}/bin/volume-change 5%+ on";
          "XF86AudioMute" = "${volume-change} toggle";
        };
    };
  };
}
