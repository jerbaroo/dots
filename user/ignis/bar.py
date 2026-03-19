import asyncio
import datetime
import re
import subprocess
import time

from collections import defaultdict
from ignis import utils
from ignis.menu_model import IgnisMenuItem, IgnisMenuModel, IgnisMenuSeparator
from ignis.services.applications import Application, ApplicationsService
from ignis.services.audio import AudioService
from ignis.services.hyprland import HyprlandService
from ignis.services.system_tray import SystemTrayService, SystemTrayItem
from ignis.services.upower import UPowerService
from ignis import widgets
from typing import List, Optional

audio = AudioService.get_default()
hyprlandService = HyprlandService.get_default()
system_tray = SystemTrayService.get_default()
uPowerService = UPowerService.get_default()

barName = "ignis-bar"
namespace = lambda x: f"{barName}-{x}"
tiny_spacing = 4
sml_spacing = 6
icon_size = 16


def exec(cmd: str) -> None:
    asyncio.create_task(utils.exec_sh_async(cmd))


def battery():
    battery = uPowerService.batteries[0]
    return widgets.Box(
        css_classes=["bar-button", "battery"],
        child=utils.Poll(
            100, # 0.1s
            lambda self:
                [ widgets.Icon(image=battery.icon_name, pixel_size=icon_size)
                , widgets.Label(label=f"{battery.percent:.0f}")
                ]
        ).bind("output")
    )


def do_not_disturb():

    def read_do_not_disturb_status():
      result = subprocess.check_output("swaync-client -D", shell=True, text=True)
      if result == 'true':
          return True
      if result == 'false':
          return False
      raise Exception(f"Unknown do not disturb status {result}")

    def do_not_disturb_icon_name():
        if read_do_not_disturb_status():
            return "notifications-disabled-symbolic"
        return "notifications-symbolic"

    box = widgets.Box(
        css_classes=["bar-button", "do-not-disturb"],
        child=utils.Poll(
            100, # 0.1s
            lambda self: [
                widgets.Icon(image=do_not_disturb_icon_name(), pixel_size=icon_size)
            ]
        ).bind("output")
    )

    return widgets.EventBox(
        on_click=lambda x: exec("swaync-client -d -sw"),
        child=[box],
    )


def volume() -> widgets.EventBox:

    box = widgets.Box(
            css_classes=["bar-button", "volume"],
            child=[
                widgets.Icon(
                    image=audio.speaker.bind("icon_name"),
                    pixel_size=icon_size,
                    style=f"margin-right: {tiny_spacing}px;"
                ),
                widgets.Label(
                    label=audio.speaker.bind("volume", transform=lambda p: f"{p}")
                ),
            ]
        )

    return widgets.EventBox(
        on_scroll_up=lambda x: exec("wpctl set-volume @DEFAULT_SINK@ 5%+"),
        on_scroll_down=lambda x: exec("wpctl set-volume @DEFAULT_SINK@ 5%-"),
        child=[box],
    )


def scroll_workspaces(f) -> None:
    target = f(hyprlandService.active_workspace.id)
    if target == 11:  # Max 10 workspaces
        return
    hyprlandService.switch_to_workspace(target)


active_workspaces = defaultdict(lambda: -1)
def workspace_buttons(bar_monitor: int, workspaces: List[dict]) -> List[widgets.Button]:
    active_workspace = hyprlandService.active_workspace.id
    active_workspace_monitor = hyprlandService.active_workspace.monitor_id
    active_workspaces[active_workspace_monitor] = active_workspace

    def active_or_open_workspace_class(id_: int):
        if id_ == active_workspace: return "active-workspace" 
        if id_ == active_workspaces[bar_monitor]: return "open-workspace"   
        return ""

    return [
        widgets.Button(
            css_classes=[
                "bar-button",
                active_or_open_workspace_class(w.id),
                "workspace-button",
            ],
            on_click=lambda x, id=w.id: hyprlandService.switch_to_workspace(id),
            child=widgets.Label(
                css_classes=["workspace-button-label"],
                label=str(w.id)[-1]
            ),
        )
        for w in workspaces
        if w.monitor_id == bar_monitor
    ]


def workspaces(monitor: int) -> widgets.EventBox:
    return widgets.EventBox(
        on_scroll_up=lambda x: scroll_workspaces(lambda y: y + 1),
        on_scroll_down=lambda x: scroll_workspaces(lambda y: y - 1),
        css_classes=["workspaces"],
        spacing=sml_spacing,
        child=hyprlandService.bind_many(
            ["active_workspace", "workspaces"],
            transform=lambda _, workspaces: workspace_buttons(monitor, workspaces),
        )
    )


def left(monitor: int) -> widgets.Box:
    return widgets.Box(
        css_classes=["bar-left"],
        child=[workspaces(monitor)]
    )


def center() -> widgets.Label:
    return widgets.Label(
        css_classes=["bar-center"],
        label=utils.Poll(
            1_000, lambda self: datetime.datetime.now().strftime("%b %-d %H:%M")
        ).bind("output"),
    )


def power_menu() -> widgets.Button:

    return widgets.Button(
        css_classes=["bar-button ", "powermenu-button"],
        on_click=lambda _: exec("os-logout-menu"),
        child=widgets.Box(
            child=[widgets.Icon(image="system-shutdown-symbolic", pixel_size=icon_size)]
        ),
    )


def tray_item(item: SystemTrayItem) -> widgets.Button:
    if item.menu:
        menu = item.menu.copy()
    else:
        menu = None

    return widgets.Button(
        child=widgets.Box(
            child=[
                widgets.Icon(image=item.bind("icon"), pixel_size=icon_size),
                menu,
            ]
        ),
        setup=lambda self: item.connect("removed", lambda x: self.unparent()),
        tooltip_text=item.bind("tooltip"),
        on_click=lambda x: menu.popup() if menu else None,
        on_right_click=lambda x: menu.popup() if menu else None,
        css_classes=["bar-button", "system-tray-button"],
    )


def tray():
    return widgets.Box(
        setup=lambda self: system_tray.connect(
            "added", lambda x, item: self.append(tray_item(item))
        ),
        spacing=sml_spacing,
    )


def right() -> widgets.Box:
    return widgets.Box(
        css_classes=["bar-right"],
        spacing=sml_spacing,
        child=[volume(), battery(), do_not_disturb(), power_menu()],
    )


def bar(monitor: int) -> widgets.Window:
    return widgets.Window(
        anchor=["left", "top", "right"],
        css_classes=["bar-window"],
        exclusivity="exclusive",
        layer="bottom",
        namespace=namespace(monitor),
        monitor=monitor,
        child=widgets.CenterBox(
            css_classes=["bar-center-box"],
            start_widget=left(monitor),
            center_widget=center(),
            end_widget=right(),
        ),
    )
