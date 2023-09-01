#!/usr/bin/env bash

# Script for powering up an Onkyo amplituner.
# Executed by raspotify on volume increase event.
# The event data are passed in environment variables.
if [ -z "$PLAYER_EVENT" ] || [ "$PLAYER_EVENT" == "volume_set" ]; then
  echo "New session started — powering up onkyo!"
  {{ONKYO_ENTRYPOINT}} --host {{ONKYO_HOST}} --port {{ONKYO_PORT}} system-power=on
fi
