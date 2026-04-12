import asyncio
import datetime
import json

try:
    import nix_paths
except ModuleNotFoundError:

    class MockPaths:
        AUDIO_GUI_CMD = "wiremix"
        POWER_PROFILES_CMD = "powerprofilesctl"

    nix_paths = MockPaths()
    print(f"Mocking nix_paths in development")
from collections import defaultdict
from gi.repository import Gdk
from ignis import utils, widgets
from ignis.services.audio import AudioService
from ignis.services.bluetooth import BluetoothService
from ignis.services.fetch import FetchService
from ignis.services.hyprland import HyprlandService
from ignis.services.system_tray import SystemTrayItem, SystemTrayService
from ignis.services.upower import UPowerService
from ignis.variable import Variable
from typing import List

audio = AudioService.get_default()
bluetooth = BluetoothService.get_default()
fetch = FetchService.get_default()
hyprlandService = HyprlandService.get_default()
system_tray = SystemTrayService.get_default()
uPowerService = UPowerService.get_default()

barName = "ignis-bar"
namespace = lambda x: f"{barName}-{x}"
tiny_spacing = 4
sml_spacing = 6
icon_size = 18


def button_widget(**kwargs):
    return widgets.Button(cursor=Gdk.Cursor.new_from_name("pointer"), **kwargs)


def exec(cmd: str) -> None:
    asyncio.create_task(utils.exec_sh_async(cmd))


##### RHS Buttons ##############################################################


def battery():
    battery = uPowerService.batteries[0]
    return widgets.Box(
        css_classes=["battery"],
        child=[
            widgets.Icon(image=battery.bind("icon_name"), pixel_size=icon_size),
            widgets.Label(
                label=battery.bind("percent", transform=lambda p: f"{p:.0f}%")
            ),
        ],
    )


def bluetooth_button() -> widgets.Button:
    bt_device_name = Variable("")

    def sync_bt_device():
        devices = bluetooth.connected_devices
        if devices:
            if len(devices) > 1:
                additional_devices_str = f" +{len(devices) - 1}"
            else:
                additional_devices_str = ""
            bt_device_name.value = f"{devices[0].name}{additional_devices_str}"
        else:
            bt_device_name.value = ""

    bluetooth.connect("notify::connected-devices", sync_bt_device)

    async def initial_bt_sync():
        # Wait for UI to be rendered before running.
        await asyncio.sleep(0.01)
        sync_bt_device()

    asyncio.create_task(initial_bt_sync())

    def toggle_power():
        bluetooth.powered = not bluetooth.powered

    return button_widget(
        css_classes=["bar-button", "bluetooth"],
        on_click=lambda _: toggle_power(),
        on_right_click=lambda _: exec(nix_paths.BLUETOOTH_GUI_CMD),
        child=widgets.Box(
            spacing=tiny_spacing,
            child=[
                widgets.Icon(
                    image=bluetooth.bind(
                        "powered",
                        transform=lambda p: (
                            "bluetooth-active-symbolic"
                            if p
                            else "bluetooth-disabled-symbolic"
                        ),
                    ),
                    pixel_size=icon_size,
                ),
                widgets.Label(
                    label=bt_device_name.bind("value"),
                    # Hide the label if no devices are connected.
                    visible=bt_device_name.bind(
                        "value", transform=lambda d: len(d) > 0
                    ),
                ),
            ],
        ),
    )


class CPUMonitor:
    def __init__(self):
        self.last_cpu_idle = 0.0
        self.last_cpu_total = 0.0

    def get_cpu(self, *args) -> float:
        with open("/proc/stat", "r") as f:
            components = [float(x) for x in f.readline().strip().split()[1:]]
        idle = components[3] + components[4]
        total = sum(components)
        idle_delta = idle - self.last_cpu_idle
        total_delta = total - self.last_cpu_total
        self.last_cpu_idle = idle
        self.last_cpu_total = total
        return (1.0 - (idle_delta / total_delta)) * 100.0


cpu_mon = CPUMonitor()
cpu_poll = utils.Poll(2000, cpu_mon.get_cpu)


def cpu_button() -> widgets.Button:
    return button_widget(
        css_classes=["bar-button", "cpu"],
        on_click=lambda _: exec("ghostty -e htop"),  # TODO
        child=widgets.Box(
            spacing=tiny_spacing,
            child=[
                widgets.Icon(image="cpu-symbolic", pixel_size=icon_size),
                widgets.Label(
                    label=cpu_poll.bind("output", transform=lambda c: f"{c:.0f}%")
                ),
            ],
        ),
    )


def memory_button() -> widgets.Button:
    return button_widget(
        css_classes=["bar-button", "ram"],
        on_click=lambda _: exec("ghostty -e htop"),
        child=widgets.Box(
            spacing=tiny_spacing,
            child=[
                widgets.Icon(image="memory-symbolic", pixel_size=icon_size),
                widgets.Label(
                    label=fetch.bind(
                        "mem_used",
                        transform=lambda used: (
                            f"{(used / fetch.mem_total) * 100:.0f}%"
                            if fetch.mem_total > 0
                            else "0%"
                        ),
                    )
                ),
            ],
        ),
    )


notification_status = Variable({"count": 0, "dnd": False})
notification_status.connect(
    "notify::value", lambda x, _: print("Notification status changed!: ", x.value)
)


async def _watch_notification_status():
    proc = await asyncio.create_subprocess_shell(
        "swaync-client -s",
        stdout=asyncio.subprocess.PIPE,
    )
    while True:
        line = await proc.stdout.readline()
        data = json.loads(line.decode("utf-8").strip())
        notification_status.value = {"count": data["count"], "dnd": data["dnd"]}


asyncio.create_task(_watch_notification_status())


def do_not_disturb() -> widgets.Button:
    return button_widget(
        css_classes=["bar-button", "do-not-disturb"],
        on_click=lambda _: exec("swaync-client -d -sw"),
        child=widgets.Box(
            child=[
                widgets.Icon(
                    image=notification_status.bind(
                        "value",
                        transform=lambda s: (
                            "notifications-disabled-symbolic"
                            if s["dnd"]
                            else "notifications-symbolic"
                        ),
                    ),
                    pixel_size=icon_size,
                )
            ]
        ),
    )


def notification_count() -> widgets.Button:
    return button_widget(
        css_classes=["bar-button", "notification-count"],
        on_click=lambda _: exec("swaync-client -t -sw"),
        child=widgets.Box(
            spacing=tiny_spacing,
            child=[
                widgets.Icon(
                    image=notification_status.bind(
                        "value",
                        transform=lambda s: (
                            "mail-unread-symbolic"
                            if s["count"] > 0
                            else "mail-read-symbolic"
                        ),
                    ),
                    pixel_size=icon_size + 4,
                ),
                widgets.Label(
                    label=notification_status.bind(
                        "value", transform=lambda s: str(s["count"])
                    ),
                    css_classes=["notification-count-label"],
                ),
            ],
        ),
    )


def performance_menu(monitor=0) -> widgets.Button:

    all_profiles = Variable(["power-saver", "balanced", "performance"])
    all_profiles.connect(
        "notify::value",
        lambda x, _: print("Power profiles available changed!: ", x.value),
    )

    async def get_profiles():
        proc = await asyncio.create_subprocess_exec(
            nix_paths.POWER_PROFILES_CMD,
            "list",
            stdout=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        all_profiles.value = [
            line.strip(" *:")
            for line in stdout.decode("utf-8").splitlines()
            if line.strip().endswith(":")
        ]

    asyncio.create_task(get_profiles())

    current_profile = Variable("balanced")
    current_profile.connect(
        "notify::value", lambda x, y: print("Power profile changed!: ", x.value)
    )

    async def poll_current_profile():
        while True:
            proc = await asyncio.create_subprocess_exec(
                nix_paths.POWER_PROFILES_CMD,
                "get",
                stdout=asyncio.subprocess.PIPE,
            )
            stdout, _ = await proc.communicate()
            new_profile = stdout.decode("utf-8").strip()
            if new_profile != current_profile.value:
                current_profile.value = new_profile
            await asyncio.sleep(2)

    asyncio.create_task(poll_current_profile())

    profile_icons = {
        "balanced": "power-profile-balanced-symbolic",
        "performance": "power-profile-performance-symbolic",
        "power-saver": "power-profile-power-saver-symbolic",
    }

    def get_next_profile():
        cycle = {
            "performance": "power-saver",
            "balanced": "performance",
            "power-saver": "balanced",
        }
        # If a next power-profile is defined, use that..
        next_profile = cycle.get(current_profile.value)
        if next_profile is not None and next_profile in all_profiles.value:
            return next_profile
        # ..else jump to the next profile in the list 'all_profiles'.
        current_index = all_profiles.value.index(current_profile.value)
        next_index = (current_index + 1) % len(all_profiles.value)
        return all_profiles.value[next_index]

    def set_next_profile():
        next_profile = get_next_profile()

        async def apply_and_update():
            proc = await asyncio.create_subprocess_exec(
                nix_paths.POWER_PROFILES_CMD, "set", next_profile
            )
            await proc.communicate()
            # . Now that the OS is updated, change the UI safely!
            current_profile.value = next_profile

        asyncio.create_task(apply_and_update())

    return button_widget(
        css_classes=["bar-button", "performance-button"],
        on_click=lambda _: set_next_profile(),
        child=widgets.Box(
            child=[
                widgets.Icon(
                    image=current_profile.bind(
                        "value",
                        transform=lambda p: profile_icons.get(
                            p, "dialog-question-symbolic"
                        ),
                    )
                ),
            ]
        ),
    )


def power_menu(monitor: int) -> widgets.Button:

    return button_widget(
        css_classes=["bar-button", "powermenu-button"],
        on_click=lambda _: exec(f"ignis toggle-window ignis-logout-menu-{monitor}"),
        child=widgets.Box(
            child=[
                widgets.Icon(image="system-shutdown-symbolic", pixel_size=icon_size + 4)
            ]
        ),
    )


def tray_item(item: SystemTrayItem) -> widgets.Button:
    if item.menu:
        menu = item.menu.copy()
    else:
        menu = None

    return button_widget(
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


def volume() -> widgets.EventBox:
    box = widgets.Box(
        child=[
            widgets.Icon(
                image=audio.speaker.bind("icon_name"),
                pixel_size=icon_size,
                style=f"margin-right: {tiny_spacing}px;",
            ),
            widgets.Label(
                label=audio.speaker.bind("volume", transform=lambda p: f"{p}%")
            ),
        ]
    )

    # For the "button" look and click action.
    button = button_widget(
        css_classes=["bar-button", "volume"],
        on_click=lambda _: exec(nix_paths.AUDIO_GUI_CMD),
        child=box,
    )

    return widgets.EventBox(
        on_scroll_up=lambda _: exec("wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+"),
        on_scroll_down=lambda _: exec("wpctl set-volume @DEFAULT_SINK@ 5%-"),
        child=[button],
    )


##### LHS Buttons ##############################################################


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
        if id_ == active_workspace:
            return "active-workspace"
        if id_ == active_workspaces[bar_monitor]:
            return "open-workspace"
        return ""

    return [
        button_widget(
            css_classes=[
                "bar-button",
                active_or_open_workspace_class(w.id),
                "workspace-button",
            ],
            on_click=lambda x, id=w.id: hyprlandService.switch_to_workspace(id),
            child=widgets.Label(
                css_classes=["workspace-button-label"], label=str(w.id)[-1]
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
        ),
    )


##### Left, right & center combined ############################################


def bar(monitor: int) -> widgets.Window:
    return widgets.Window(
        anchor=["left", "top", "right"],
        css_classes=["bar-window"],
        exclusivity="exclusive",
        layer="top",
        namespace=namespace(monitor),
        monitor=monitor,
        child=widgets.CenterBox(
            css_classes=["bar-center-box"],
            start_widget=left(monitor),
            center_widget=center(),
            end_widget=right(monitor),
        ),
    )


def center() -> widgets.Label:
    return widgets.Label(
        css_classes=["bar-center"],
        label=utils.Poll(
            1_000, lambda _: datetime.datetime.now().strftime("%b %-d %H:%M")
        ).bind("output"),
    )


def left(monitor: int) -> widgets.Box:
    return widgets.Box(css_classes=["bar-left"], child=[workspaces(monitor)])


def right(monitor: int) -> widgets.Box:
    return widgets.Box(
        css_classes=["bar-right"],
        spacing=sml_spacing,
        child=[
            battery(),
            cpu_button(),
            memory_button(),
            performance_menu(),
            bluetooth_button(),
            # TODO wifi
            volume(),
            do_not_disturb(),
            notification_count(),
            power_menu(monitor),
        ],
    )
