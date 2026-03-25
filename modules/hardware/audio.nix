{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host;
      toggle-speaker = pkgs.writeShellApplication {
        name = "toggle-speaker";
        text = /* sh */ ''
          # Device names
          KANTO="ORA"
          TOPPING="DX5"

          # Get current default sink with asterisk
          current_line=$(wpctl status | grep -A 20 "Sinks:" | grep "\*")

          if [ -z "$current_line" ]; then
              echo "Could not determine current audio sink"
              exit 1
          fi

          # Determine which device to switch to
          if echo "$current_line" | grep -q "Kanto"; then
              target_device="$TOPPING"
              friendly_name="Headphones"
          elif echo "$current_line" | grep -q "DX5"; then
              target_device="$KANTO"
              friendly_name="Speakers"
          else
              echo "Current device is neither Kanto nor Topping, defaulting to KANTO"
              target_device="$KANTO"
              friendly_name="Speakers"
          fi

          # Get the sink ID for the target device
          sink_id=$(wpctl status | grep -A 20 "Sinks:" | grep "$target_device" | awk '{print $2}' | grep -oP '[0-9]+' | head -1 || true)

          if [ -z "$sink_id" ]; then
              noctalia-ipc toast send "{\"title\": \"Unable to switch to $friendly_name\", \"type\": \"warning\"}"
              exit 1
          fi

          # Set as default
          wpctl set-default "$sink_id"

          noctalia-ipc toast send "{\"title\": \"Switched audio to $friendly_name\"}"
        '';
      };
    in
    {
      # setup pipewire for audio
      security.rtkit.enable = true;
      services = {
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };

      environment.systemPackages =
        with pkgs;
        [
          pamixer
          pavucontrol
        ]
        ++ lib.optionals (host == "desktop") [ toggle-speaker ];

      custom.programs.noctalia.settingsReducers = [
        # toggle-speaker is only for desktop
        (
          prev:
          lib.recursiveUpdate prev {
            bar.widgets.right = map (
              widget:
              if widget.id == "Volume" then
                widget
                // {
                  middleClickCommand =
                    if host == "desktop" then (lib.getExe toggle-speaker) else "pwvucontrol || pavucontrol";
                }
              else
                widget
            ) prev.bar.widgets.right;
          }
        )
      ];

      custom.persist = {
        home.directories = [
          ".local/state/wireplumber"
        ];
      };
    };
}
