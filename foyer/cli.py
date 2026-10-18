import os
from pathlib import Path

import click

ACTIONS = click.Choice(["show", "hide", "toggle"])
# Avoid IPC method names that conflict with QuickShell's own subcommands.
ACTION_QUICKSHELL = {"show": "setShown", "hide": "setHidden", "toggle": "toggle"}


def control(entry: str, target: str, method: str) -> None:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    config_dir = Path(os.environ.get("FOYER_CONFIG_DIR") or config_home / "foyer")
    args = [
        "quickshell",
        "-p",
        str(config_dir / f"{entry}.qml"),
        "ipc",
        "call",
        target,
        method,
    ]
    try:
        os.execvp("quickshell", args)
    except OSError as error:
        raise click.ClickException(str(error)) from error


@click.group()
def cli() -> None:
    """Control a running Foyer instance."""


@cli.command()
@click.argument("action", type=ACTIONS)
def bar(action: str) -> None:
    """Show, hide, or toggle the bar."""
    control("bar", "bar", ACTION_QUICKSHELL[action])


@cli.command()
@click.argument("action", type=ACTIONS)
def launcher(action: str) -> None:
    """Show, hide, or toggle the application launcher."""
    control("app_launcher", "app-launcher", ACTION_QUICKSHELL[action])


@cli.command()
@click.argument("action", type=ACTIONS)
def notifications(action: str) -> None:
    """Show, hide, or toggle the notification center."""
    methods = {
        "show": "setNotificationCenterOpen",
        "hide": "setNotificationCenterClosed",
        "toggle": "toggleNotificationCenter",
    }
    control("bar", "notifications", methods[action])


if __name__ == "__main__":
    cli(prog_name="foyer")
