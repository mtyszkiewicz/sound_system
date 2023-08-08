PREFIX  ?= /usr/local
LIB_DIR ?= $(PREFIX)/lib
BIN_DIR ?= $(PREFIX)/bin
CFG_DIR ?= /etc

SPOTIFY_DEVICE_NAME ?= "raspotify@salon"
SPOTIFY_ONEVENT_SCRIPT = "$(BIN_DIR)/powerup-onkyo.sh"

ONKYO_ENTRYPOINT=cd $(LIB_DIR)/onkyo; ./venv/bin/python3 -m eiscp.script
ONKYO_HOST=192.168.1.16
ONKYO_PORT=60128 

DSP_EFFECTS_FILE=wiosna77
DSP_PCM_OUT=dmix:CARD=USB,DEV=0
DEFAULT_PCM_TYPE=plug
# DEFAULT_PCM_TYPE=copy
# DSP_PCM_OUT=hw:0

build: \
	prerequisites \
	build/asound.conf \
	build/powerup-onkyo.sh \
	build/raspotify.conf \
	build/dsp/ladspa_dsp.so \
	build/ladspa_dsp.conf \
	build/effects

prerequisites:
	@mkdir -p build

install: \
	$(LIB_DIR)/ladspa/ladspa_dsp.so \
	$(CFG_DIR)/raspotify/conf \
	$(BIN_DIR)/powerup-onkyo.sh \
	$(LIB_DIR)/onkyo \
	$(CFG_DIR)/asound.conf \
	$(CFG_DIR)/ladspa_dsp

	sudo systemctl start raspotify.service
	sudo systemctl enable raspotify.service
	sudo systemctl restart raspotify.service
	alsaloop -C iec958:CARD=USB,DEV=0 -P default --sync 3 --nblock --daemonize -t 12000

uninstall:
	@cd build/dsp && sudo make uninstall
	rm -rf $(CFG_DIR)/raspotify
	rm -rf $(LIB_DIR)/onkyo
	rm -rf $(LIB_DIR)/ladspa
	rm -rf $(CFG_DIR)/ladspa_dsp
	rm -f $(BIN_DIR)/powerup-onkyo.sh
	sudo systemctl stop raspotify.service
	sudo systemctl disable raspotify.service
	pkill alsaloop

clean: uninstall
	rm -rf build


build/asound.conf: templates/asound.conf
	cat templates/asound.conf \
	| sed 's|{{DSP_PCM_OUT}}|$(DSP_PCM_OUT)|g' \
	| sed 's|{{DEFAULT_PCM_TYPE}}|$(DEFAULT_PCM_TYPE)|g' \
	> build/asound.conf

build/ladspa_dsp.conf: templates/ladspa_dsp.conf
	cat templates/ladspa_dsp.conf > build/ladspa_dsp.conf

build/effects: effects/$(DSP_EFFECTS_FILE)
	cp effects/$(DSP_EFFECTS_FILE) build/effects

build/raspotify.conf: templates/raspotify.conf
	cat templates/raspotify.conf \
	| sed 's|{{LIBRESPOT_NAME}}|$(SPOTIFY_DEVICE_NAME)|g' \
	| sed 's|{{LIBRESPOT_ONEVENT}}|$(SPOTIFY_ONEVENT_SCRIPT)|g' \
	> build/raspotify.conf

build/powerup-onkyo.sh: templates/powerup-onkyo.sh build/onkyo/venv
	cat templates/powerup-onkyo.sh \
	| sed 's|{{ONKYO_ENTRYPOINT}}|$(ONKYO_ENTRYPOINT)|g' \
	| sed 's|{{ONKYO_HOST}}|$(ONKYO_HOST)|g' \
	| sed 's|{{ONKYO_PORT}}|$(ONKYO_PORT)|g' \
	> build/powerup-onkyo.sh


build/dsp/README.md: # check if repo exists
	@git clone https://github.com/bmc0/dsp build/dsp

build/dsp/ladspa_dsp.so: build/dsp/README.md
	cd build/dsp && ./configure && make


build/onkyo/README.rst:
	@git clone https://github.com/miracle2k/onkyo-eiscp build/onkyo

build/onkyo/venv: build/onkyo/README.rst
	cd build/onkyo && python3 -m venv venv && ./venv/bin/pip install xmltodict netifaces docopt


$(CFG_DIR)/ladspa_dsp: build/ladspa_dsp.conf build/effects
	install -Dm 755 build/ladspa_dsp.conf $(CFG_DIR)/ladspa_dsp/config
	install -Dm 755 build/effects $(CFG_DIR)/ladspa_dsp/effects

$(CFG_DIR)/asound.conf: build/asound.conf
	install -Dm 755 build/asound.conf $(CFG_DIR)/asound.conf

$(BIN_DIR)/powerup-onkyo.sh: build/powerup-onkyo.sh
	install -m 755 build/powerup-onkyo.sh $(BIN_DIR)/powerup-onkyo.sh

$(LIB_DIR)/ladspa/ladspa_dsp.so: build/dsp/ladspa_dsp.so
	cd build/dsp && sudo make install

$(LIB_DIR)/onkyo: build/onkyo/venv
	cp -r build/onkyo $(LIB_DIR)/onkyo

$(CFG_DIR)/raspotify/conf: build/raspotify.conf
	install -Dm 600 build/raspotify.conf $(CFG_DIR)/raspotify/conf

.PHONY: all build prerequisites install uninstall clean