import toml
from jinja2 import Template

template_path = "/home/mtyszkiewicz/sound_system/templates/spotify"

config = toml.load("../config.toml")

def generate_spotifyd_config():
    exec_command = f"/bin/sh -c '"
    exec_command += config["spotifyd"]["exec"]