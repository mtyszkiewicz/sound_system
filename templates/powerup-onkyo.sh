#!/usr/bin/env bash

if [ -z "$PLAYER_EVENT" ] || [ "$PLAYER_EVENT" == "volume_set" ]; then
  echo "New session started — powering up onkyo!"
  {{ONKYO_ENTRYPOINT}} --host {{ONKYO_HOST}} --port {{ONKYO_PORT}} system-power=on
fi
