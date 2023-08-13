#!/usr/bin/env bash

source_id=$(amixer --card 3 cget name='PCM Capture Source' \
    | grep -o ': values=[0-9]*' | awk -F= '{ print $2 }')

if [ $source_id -eq 1 ]; then
    new_source_id=2
    echo "Switched source: Line -> IEC958"
elif [ $source_id -eq 2 ]; then
    new_source_id=1
    echo "Switched source: IEC958 -> Line"
fi

amixer --card 3 --quiet cset name='PCM Capture Source' $new_source_id
