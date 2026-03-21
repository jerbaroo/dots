import click
import json
import os
import subprocess

# Pull the injected variables from the environment.
# Fallback to standard commands if running outside of Nix.
HYPRCTL = os.environ.get("HYPRCTL_PATH", "hyprctl")
IGNIS = os.environ.get("IGNIS_PATH", "ignis")


##### ROOT #####################################################################


@click.group()
def cli():
    pass


@cli.command()
def info():
    click.echo(f"HYPRCTL path: {HYPRCTL}")
    click.echo(f"IGNIS path: {IGNIS}")


##### MONITOR ##################################################################


@cli.group()
def monitor():
    pass


@monitor.command()
def current():
    output = subprocess.check_output(f"{HYPRCTL} -j monitors", shell=True, text=True)
    for monitor in json.loads(output):
        if monitor["focused"]:
            print(monitor["id"])


##### UI #######################################################################


@cli.group()
def ui():
    pass


@ui.command()
def reload():
    subprocess.run([IGNIS, "reload"])


if __name__ == '__main__':
    cli()
