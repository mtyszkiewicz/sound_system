#!/usr/bin/env bash

ONKYO_ENTRYPOINT={{ONKYO_ENTRYPOINT}}
ONKYO_HOST={{ONKYO_HOST}}
ONKYO_PORT={{ONKYO_PORT}}

if [ -z "$PLAYER_EVENT" ] || [ "$PLAYER_EVENT" == "started" ]; then
  echo "New session started — powering up onkyo!"
  $ONKYO_ENTRYPOINT --host $ONKYO_HOST --port $ONKYO_PORT system-power=on
fi
