#!/nix/store/gik3rh1vz2jlgnifb9dh6vc6sxwwz9jj-bash-5.3p9/bin/bash
set -o errexit
set -o nounset
set -o pipefail

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

# Function to fetch the WirePlumber sink ID
get_sink_id() {
    timeout 1 wpctl status | grep -A 20 "Sinks:" | grep "$target_device" | awk '{print $2}' | grep -oP '[0-9]+' | head -1 || true
}

# Initial attempt to get the sink ID
sink_id=$(get_sink_id)

# If the sink ID doesn't exist, turn on the DAC via Home Assistant and retry
if [ -z "$sink_id" ]; then
    # 1. Trigger Home Assistant to toggle/turn on the DAC
    curl -s -X POST \
        -H "Authorization: Bearer $(cat /run/secrets/home_assistant_token)" \
        -H "Content-Type: application/json" \
        -d '{"entity_id": "switch.dac"}' \
        "http://$(cat /run/secrets/home_assistant_host)/api/services/homeassistant/toggle"

    echo "POLLING"

    # 2. Retry polling for the sink ID for up to 5 seconds (25 attempts * 0.2s)
    count=0
    max_attempts=25
    while [ $count -lt $max_attempts ]; do
        echo "SLEEP"
        sleep 0.2
        sink_id=$(get_sink_id)

        if [ -n "$sink_id" ]; then
            echo "FOUND SINK ID"
            break
        fi
        ((++count))
    done
fi

echo "SINK ID: $sink_id"

# Final check: If it's still empty after 5 seconds, fail out
if [ -z "$sink_id" ]; then
    noctalia-ipc toast send "{\"title\": \"Unable to switch to $friendly_name\", \"type\": \"warning\"}"
    exit 1
fi

# Set as default
wpctl set-default "$sink_id"

noctalia-ipc toast send "{\"title\": \"Switched audio to $friendly_name\"}"
