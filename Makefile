PREFIX  ?= /usr/local
LIB_DIR ?= $(PREFIX)/lib
BIN_DIR ?= $(PREFIX)/bin
CFG_DIR ?= /etc

SPOTIFY_DEVICE_NAME ?= "raspotify@salon"
SPOTIFY_ONEVENT_SCRIPT = "$(BIN_DIR)/powerup-onkyo.sh"

ONKYO_ENTRYPOINT=cd $(LIB_DIR)/onkyo; ./venv/bin/python3 -m eiscp.script
ONKYO_HOST=192.168.1.16
ONKYO_PORT=60128 

.PHONY: all build prerequisites install uninstall clean
#.SILENT:

all: build

build: prerequisites build/asound.conf build/raspotify.conf build/ladspa_dsp.conf build/dsp/ladspa_dsp.so build/powerup-onkyo.sh

prerequisites:
	@mkdir -p build

install: $(LIB_DIR)/ladspa/ladspa_dsp.so $(CFG_DIR)/raspotify/conf $(BIN_DIR)/powerup-onkyo.sh $(LIB_DIR)/onkyo
	systemctl start raspotify.service
	systemctl enable raspotify.service
	systemctl restart raspotify.service

uninstall:
	@cd build/dsp && sudo make uninstall
	rm -rf $(CFG_DIR)/raspotify
	rm -rf $(LIB_DIR)/onkyo
	rm -f $(BIN_DIR)/powerup-onkyo.sh
	systemctl stop raspotify.service
	systemctl disable raspotify.service

clean: uninstall
	rm -rf build


build/asound.conf: templates/asound.conf
	@cat templates/asound.conf > build/asound.conf

build/ladspa_dsp.conf: templates/ladspa_dsp.conf
	@cat templates/ladspa_dsp.conf > build/ladspa_dsp.conf

build/raspotify.conf: templates/raspotify.conf
	@cat templates/raspotify.conf \
	| sed 's|{{LIBRESPOT_NAME}}|$(SPOTIFY_DEVICE_NAME)|g' \
	| sed 's|{{LIBRESPOT_ONEVENT}}|$(SPOTIFY_ONEVENT_SCRIPT)|g' \
	> build/raspotify.conf


build/dsp/README.md: # check if repo exists
	@git clone https://github.com/bmc0/dsp build/dsp

build/dsp/ladspa_dsp.so: build/dsp/README.md
	@cd build/dsp && ./configure && make

build/onkyo/README.rst:
	@git clone https://github.com/miracle2k/onkyo-eiscp build/onkyo

build/onkyo/venv: build/onkyo/README.rst
	cd build/onkyo && python3 -m venv venv && ./venv/bin/pip install xmltodict netifaces docopt

build/powerup-onkyo.sh: build/onkyo/venv
	@cat templates/powerup-onkyo.sh \
	| sed 's|{{ONKYO_ENTRYPOINT}}|$(ONKYO_ENTRYPOINT)|g' \
	| sed 's|{{ONKYO_HOST}}|$(ONKYO_HOST)|g' \
	| sed 's|{{ONKYO_PORT}}|$(ONKYO_PORT)|g' \
	> build/powerup-onkyo.sh


$(LIB_DIR)/ladspa/ladspa_dsp.so: build/dsp/ladspa_dsp.so
	@cd build/dsp && sudo make install

$(LIB_DIR)/onkyo: build/onkyo/venv
	cp -r build/onkyo $(LIB_DIR)/onkyo

$(BIN_DIR)/powerup-onkyo.sh: build/powerup-onkyo.sh
	install -m 755 build/powerup-onkyo.sh $(BIN_DIR)/powerup-onkyo.sh

$(CFG_DIR)/raspotify/conf: build/raspotify.conf
	install -Dm 755 build/raspotify.conf $(CFG_DIR)/raspotify/conf