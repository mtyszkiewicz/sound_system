#!/usr/bin/env bash

cd /lib/onkyo-eiscp
python3 -m eiscp.script --host 192.168.1.16 --port 60128 system-power=on