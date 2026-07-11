{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host user;
      toggle-speaker = pkgs.writeShellApplication {
        name = "toggle-speaker";
        text = lib.optionalString (host == "desktop") /* sh */ ''
          # Device names
          KANTO="ORA"
          TOPPING="DX5"

          # get current default sink
          current_line=$(wpctl status | grep -A 20 "Sinks:" | grep "\*")

          if [ -z "$current_line" ]; then
              echo "Could not determine current audio sink"
              exit 1
          fi

          # determine which device to switch to
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

          # fetch sink ID from WirePlumber
          get_sink_id() {
              wpctl status | grep -A 20 "Sinks:" | grep "$target_device" | awk '{print $2}' | grep -oP '[0-9]+' | head -1 || true
          }

          sink_id=$(get_sink_id)

          # if the sink id doesn't exist, turn on the DAC via home assistant and retry
          if [ -z "$sink_id" ]; then
              curl -s -X POST \
                -H "Authorization: Bearer $(cat ${config.sops.secrets.home_assistant_token.path})" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "switch.dac"}' \
                "http://$(cat ${config.sops.secrets.home_assistant_host.path})/api/services/homeassistant/turn_on"

              # poll sink ID for up to 5 seconds (25 attempts * 0.2s)
              count=0
              max_attempts=25
              while [ $count -lt $max_attempts ]; do
                  sleep 0.2
                  sink_id=$(get_sink_id)

                  if [ -n "$sink_id" ]; then
                      break
                  fi
                  ((++count))
              done
          fi

          # still not found after 5s, bail
          if [ -z "$sink_id" ]; then
              noctalia msg notification-show "{\"summary\": \"Unable to switch to $friendly_name\", \"icon\": \"alert-circle\"}"
              exit 1
          fi

          # set as new audio device
          wpctl set-default "$sink_id"

          noctalia msg notification-show "{\"summary\": \"Switched audio to $friendly_name\", \"icon\": \"music\"}"
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

      environment.systemPackages = with pkgs; [
        pamixer
        pavucontrol
        toggle-speaker
        (pkgs.makeDesktopItem {
          name = "Toggle Speaker";
          desktopName = "Toggle Speaker";
          exec = lib.getExe toggle-speaker;
          icon = "audio-x-generic";
          terminal = false;
          categories = [ "Utility" ];
        })
      ];

      sops.secrets = lib.mkIf (host == "desktop") {
        home_assistant_host.owner = user;
        home_assistant_token.owner = user;
      };

      custom.persist = {
        home.directories = [
          ".local/state/wireplumber"
        ];
      };
    };
}
