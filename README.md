# Sound System
My Sound System open source stack :~)

## Dependencies
```
sudo apt install -y git libasound2-dev libssl-dev pkg-config python3-venv python3.9-dev ladspa-sdk
sudo apt-get -y install curl && curl -sL https://dtcooper.github.io/raspotify/install.sh | sh
```

## Terratec Aureon 7.1 USB
You can adjust this sound card's controls using either `alsamixer` TUI, or `amixer` CLI.
The device itself has 4 sources:
 * Mic 1 - 2 channel input for Microphone #1
 * Mic 2 - 2 channel input for Microphone #2
 * Line - 4 channel Jack input
 * IEC958 - 4 channel S/PDIF (optical) input

## Snapcast dependencies
```
sudo apt-get install build-essential cmake
sudo apt-get install libasound2-dev libpulse-dev libvorbisidec-dev libvorbis-dev libopus-dev libflac-dev libsoxr-dev alsa-utils libavahi-client-dev avahi-daemon libexpat1-dev
```
