import asyncio
import subprocess
from ignis import widgets, utils
from ignis.app import IgnisApp


def logout_name(monitor: int):
    return f"ignis-logout-menu-{monitor}"


# TODO factor out.
def exec(cmd: str) -> None:
    asyncio.create_task(utils.exec_sh_async(cmd))


def close_logout(ignis_app: IgnisApp, monitor: int):
    ignis_app.close_window(logout_name(monitor))


def button(icon_name: str, command: str, ignis_app: IgnisApp, monitor: int):

    def execute():
        print(f"Executing: {command}")
        close_logout(ignis_app, monitor)
        subprocess.Popen(command, shell=True)

    return widgets.Button(
        css_classes=["logout-menu-button"],
        on_click=lambda _: execute(),
        child=widgets.Icon(icon_name=icon_name, pixel_size=64),
    )


def logout_menu(ignis_app: IgnisApp, monitor: int) -> widgets.Window:
    buttons = [
        ("system-lock-screen-symbolic", "os-lock"),
        ("system-log-out-symbolic", "hyprctl dispatch exit"),
        ("system-suspend-symbolic", "systemctl suspend"),
        ("system-reboot-symbolic", "systemctl reboot"),
        ("system-shutdown-symbolic", "systemctl poweroff"),
    ]

    button_box = widgets.Box(
        css_classes=["logout-box"],
        halign="center",
        valign="center",
        child=[button(icon, cmd, ignis_app, monitor) for icon, cmd in buttons],
    )

    return widgets.Window(
        anchor=["top", "right", "bottom", "left"],
        css_classes=["logout-menu-window"],
        exclusivity="ignore",
        kb_mode="on_demand",
        layer="top",
        namespace=logout_name(monitor),
        popup=True,  # Close on ESC.
        visible=False,  # Initially hidden.
        child=widgets.Overlay(
            child=widgets.Button(
                css_classes=["logout-menu-overlay"],
                on_click=lambda x: close_logout(ignis_app, monitor),
            ),
            overlays=[button_box],
        ),
    )
