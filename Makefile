PREFIX ?= /usr/local
BIN_DIR ?= $(PREFIX)/bin
LIB_DIR ?= $(PREFIX)/lib
SHARE_DIR ?= $(PREFIX)/share
CONFIG_DIR ?= /etc
SYSTEMD_DIR ?= /etc/systemd/system

BUILD_LIB_DIR = build/lib
BUILD_BIN_DIR = build/bin
BUILD_SYSTEMD_DIR = build/systemd
BUILD_CONFIG_DIR = build/config

ONKYO_HOST ?= 192.168.1.16
ONKYO_PORT ?= 60128
ONKYO_POWERUP_COMMAND ?= "$(BIN_DIR)/onkyo --host $(ONKYO_HOST) --port $(ONKYO_PORT) system-power=on"

SPOTIFYD_VERSION ?= 0.3.5
SPOTIFYD_RELEASE ?= spotifyd-linux-armhf-full
SPOTIFYD_DEVICE_NAME ?= "spotifyd@raspberrypi"

SPOTIFYD_RELEASE_ARCHIVE = $(SPOTIFYD_RELEASE).tar.gz
SPOTIFYD_RELEASE_ARCHIVE_URL = "https://github.com/Spotifyd/spotifyd/releases/download/v$(SPOTIFYD_VERSION)/$(SPOTIFYD_RELEASE_ARCHIVE)"


.PHONY: all build prerequisites install uninstall clean spotifyd-build

all: build

build: prerequisites spotifyd-build $(BUILD_LIB_DIR)/dsp/dsp $(BUILD_CONFIG_DIR)/asound.conf

install: $(BIN_DIR)/onkyo $(BIN_DIR)/dsp $(CONFIG_DIR)/asound.conf $(BIN_DIR)/spotifyd $(SYSTEMD_DIR)/spotifyd.service
	sudo systemctl daemon-reload
	sudo systemctl start spotifyd.service
	sudo systemctl enable spotifyd.service


$(BIN_DIR)/onkyo: $(BUILD_LIB_DIR)/onkyo-eiscp/.venv/bin/onkyo
	sudo install -m 755 $(BUILD_LIB_DIR)/onkyo-eiscp/.venv/bin/onkyo $(BIN_DIR)/onkyo

$(BIN_DIR)/spotifyd: $(BUILD_BIN_DIR)/spotifyd
	sudo install -m 755 $(BUILD_BIN_DIR)/spotifyd $(BIN_DIR)/spotifyd

$(BIN_DIR)/dsp: $(BUILD_LIB_DIR)/dsp/dsp
	sudo install -Dm 755 $(BUILD_LIB_DIR)/dsp/dsp $(BIN_DIR)/dsp
	sudo install -Dm 644 $(BUILD_LIB_DIR)/dsp/dsp.1 $(SHARE_DIR)/man/man1/dsp.1

$(SYSTEMD_DIR)/spotifyd.service: $(BUILD_SYSTEMD_DIR)/spotifyd.service
	cp $(BUILD_SYSTEMD_DIR)/spotifyd.service $(SYSTEMD_DIR)/spotifyd.service

$(CONFIG_DIR)/asound.conf: $(BUILD_CONFIG_DIR)/asound.conf
	cp $(BUILD_CONFIG_DIR)/asound.conf $(CONFIG_DIR)/asound.conf

uninstall:
	sudo systemctl stop spotifyd
	sudo systemctl disable spotifyd
	rm -f $(BIN_DIR)/onkyo
	rm -f $(BIN_DIR)/spotifyd
	rm -f $(BIN_DIR)/dsp
	rm -f $(SHARE_DIR)/man/man1/dsp.1
	rm -f $(CONFIG_DIR)/asound.conf

clean: uninstall
	rm -rf build

test:
	aplay assets/universal-studios.wav

prerequisites:
	@mkdir -p $(BUILD_BIN_DIR)
	@mkdir -p $(BUILD_CONFIG_DIR)
	@mkdir -p $(BUILD_LIB_DIR)
	@mkdir -p $(BUILD_SYSTEMD_DIR)

spotifyd-build: $(BUILD_BIN_DIR)/spotifyd $(BUILD_CONFIG_DIR)/spotifyd.conf $(BUILD_SYSTEMD_DIR)/spotifyd.service
	

$(BUILD_LIB_DIR)/onkyo-eiscp/:
	git clone https://github.com/miracle2k/onkyo-eiscp $(BUILD_LIB_DIR)/onkyo-eiscp/

$(BUILD_LIB_DIR)/onkyo-eiscp/.venv/bin/onkyo: $(BUILD_LIB_DIR)/onkyo-eiscp/
	cd $(BUILD_LIB_DIR)/onkyo-eiscp && python3 -m venv .venv && .venv/bin/easy_install onkyo-eiscp


$(BUILD_CONFIG_DIR)/asound.conf: $(BUILD_LIB_DIR)/dsp/obj/dsp 
	@cat templates/alsa/asound.conf > $(BUILD_CONFIG_DIR)/asound.conf

$(BUILD_LIB_DIR)/dsp/README.md:
	@git clone https://github.com/bmc0/dsp $(BUILD_LIB_DIR)/dsp/
	
$(BUILD_LIB_DIR)/dsp/config.mk: $(BUILD_LIB_DIR)/dsp/README.md
	cd $(BUILD_LIB_DIR)/dsp && ./configure --prefix=/usr/local

$(BUILD_LIB_DIR)/dsp/dsp: $(BUILD_LIB_DIR)/dsp/config.mk
	cd $(BUILD_LIB_DIR)/dsp && make


$(BUILD_BIN_DIR)/spotifyd:
	@mkdir -p $(BUILD_BIN_DIR)
	@wget -O /tmp/$(SPOTIFYD_RELEASE_ARCHIVE) $(SPOTIFYD_RELEASE_ARCHIVE_URL)
	tar xvf /tmp/$(SPOTIFYD_RELEASE_ARCHIVE) -C $(BUILD_BIN_DIR) spotifyd
	rm -f /tmp/$(SPOTIFYD_RELEASE_ARCHIVE)

$(BUILD_CONFIG_DIR)/spotifyd.conf: $(BUILD_LIB_DIR)/onkyo-eiscp/.venv/bin/onkyo  
	@mkdir -p $(BUILD_CONFIG_DIR)
	@cat templates/spotifyd/spotifyd.conf \
	| sed 's|{{SPOTIFYD_DEVICE_NAME}}|$(SPOTIFYD_DEVICE_NAME)|g' \
	| sed 's|{{SPOTIFYD_ONEVENT_COMMAND}}|$(ONKYO_POWERUP_COMMAND)|g' \
	> $(BUILD_CONFIG_DIR)/spotifyd.conf

$(BUILD_SYSTEMD_DIR)/spotifyd.service: $(BUILD_BIN_DIR)/spotifyd
	@mkdir -p $(BUILD_SYSTEMD_DIR)
	cat templates/spotifyd/spotifyd.service \
	| sed 's|{{BIN_DIR}}|$(BIN_DIR)|g' \
	> $(BUILD_SYSTEMD_DIR)/spotifyd.service
