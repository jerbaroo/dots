import click
import json
import os
import subprocess
from typing import Optional

# Pull the injected variables from the environment.
# Fallback to standard commands if running outside of Nix.
BLUETOOTH_GUI_CMD = os.environ.get("OS_BLUETOOTH_GUI_CMD", "blueman")
GRIM = os.environ.get("OS_GRIM_PATH", "grim")
HOSTNAME = os.environ["OS_HOSTNAME"]
HYPRCTL = os.environ.get("OS_HYPRCTL_PATH", "hyprctl")
IGNIS = os.environ.get("OS_IGNIS_PATH", "ignis")
NH = os.environ.get("OS_NH_PATH", "nh")
SLURP = os.environ.get("OS_SLURP_PATH", "slurp")
SWAPPY = os.environ.get("OS_SWAPPY_PATH", "swappy")
USERNAME = os.environ["OS_USERNAME"]


def monitor_current() -> Optional[int]:
    output = subprocess.check_output(f"{HYPRCTL} -j monitors", shell=True, text=True)
    for monitor in json.loads(output):
        if monitor["focused"]:
            return monitor["id"]


def ui_reload():
    subprocess.run([IGNIS, "reload"])


##### ROOT #####################################################################


@click.group()
def cli():
    pass


##### APPS #####################################################################


@cli.group()
def app():
    """Open apps for various purposes."""
    pass


@app.command()
def bluetooth():
    subprocess.run(BLUETOOTH_GUI_CMD, shell=True)


##### INFO #####################################################################


@cli.command()
def info():
    """Print debugging information."""
    click.echo(f"GRIM path: {GRIM}")
    click.echo(f"HYPRCTL path: {HYPRCTL}")
    click.echo(f"IGNIS path: {IGNIS}")
    click.echo(f"SLURP path: {SLURP}")
    click.echo(f"SWAPPY path: {SWAPPY}")


##### HOME #####################################################################


@cli.group()
def home():
    """Manage Home Manager configuration."""
    pass


@home.command()
def switch():
    """Switch Home Manager configuration."""
    home_path = f"/home/{USERNAME}"
    flake_path = f"{home_path}/nixos-config/.#homeConfigurations.{USERNAME}@{HOSTNAME}.activationPackage"
    click.echo(f"Switching home configuration using {flake_path}")
    subprocess.run([NH, "home", "switch", flake_path], cwd=home_path)
    # We also reload the UI to avoid issues with missing icons.
    ui_reload()


##### MONITOR ##################################################################


@cli.group()
def monitor():
    pass


@monitor.command()
def current():
    print(monitor_current())


##### NIXOS #####################################################################


@cli.group()
def nixos():
    """Manage NixOS configuration."""
    pass


@nixos.command()
def switch():
    """Switch NixOS configuration."""
    config_path = f"/home/{USERNAME}/nixos-config"
    click.echo(f"Switching NixOS configuration using {config_path}")
    subprocess.run(["sudo", "nixos-rebuild", "switch", "--flake", ".#nixos"], cwd=config_path)


##### SCREENSHOT ###############################################################


@cli.command()
def screenshot():
    """Take an interactive screenshot and open it in swappy."""
    slurp_proc = subprocess.run([SLURP], capture_output=True, text=True)
    geometry = slurp_proc.stdout.strip()
    click.echo(f"Capturing area: {geometry}")
    with subprocess.Popen([GRIM, "-l", "0", "-g", geometry, "-"], stdout=subprocess.PIPE) as grim_proc:
      subprocess.run([SWAPPY, "-f", "-"], stdin=grim_proc.stdout)


##### UI #######################################################################


@cli.group()
def ui():
    pass


@ui.group()
def menu_bar():
    pass


@menu_bar.command()
def toggle():
    subprocess.run([IGNIS, "toggle-window", f"ignis-bar-{monitor_current()}"])


@ui.command()
def reload():
    ui_reload()


if __name__ == '__main__':
    cli()
