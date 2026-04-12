import subprocess
from enum import Enum
from ignis import utils
from ignis import widgets
from ignis.app import IgnisApp
from typing import Optional, Tuple


def authenticate(password: str) -> bool:
    try:
        reset_sudo = lambda: subprocess.run(["sudo", "-k"], check=False)
        reset_sudo()
        proc = subprocess.run(
            ["sudo", "-S", "-v"],
            input=password.encode(),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if proc.returncode == 0:
            reset_sudo()
        return proc.returncode == 0
    except Exception as e:
        print(f"Authentication failed: {e}")
        return False


def namespace(connector: str) -> str:
    return f"ignis-lock-screen-{connector}"


class Lock(Enum):
    LOCK = 1
    UNLOCK = 2


def set_hyprland_mode(lock: Lock):
    submap = "locked" if lock == Lock.LOCK else "reset"
    try:
        proc = subprocess.run(
            ["hyprctl", "dispatch", "submap", submap],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        stdout = proc.stdout.decode().strip()
        if stdout != "ok":
            raise Exception(f"Hyprland stdout: ${stdout}")
        stderr = proc.stderr.decode().strip()
        if stderr != "":
            raise Exception(f"Hyprland stderr: ${stderr}")
    except Exception as e:
        print(f"Failed to set Hyprland submap: {e}")
        # Fail fast if we can't lock hyprland.
        if lock == Lock.LOCK:
            raise e


def create_lock_screen_window(
    connector: str, monitor_id: int, on_close, visible=True
) -> widgets.Window:

    def reset_entry(entry: widgets.Entry, css_classes=[], reset_text: bool = False):
        entry.css_classes = ["lock-screen-entry"] + css_classes
        if reset_text:
            entry.text = ""

    just_failed = False

    def on_accept(entry: widgets.Entry):
        reset_entry(entry, ["authenticating"])
        entry.sensitive = False

        def go():
            success = authenticate(entry.text)
            entry.sensitive = True
            if success:
                reset_entry(entry)
                on_close()
            else:
                nonlocal just_failed
                just_failed = True
                reset_entry(entry, ["error"], reset_text=True)
                entry.grab_focus()

        # Small timeout to allow render before authentication.
        utils.timeout.Timeout(50, go)

    def on_change(entry: widgets.Entry):
        nonlocal just_failed
        if just_failed:
            just_failed = False
        else:
            reset_entry(entry)

    # Password text entry.
    entry = widgets.Entry(
        css_classes=["lock-screen-entry"],
        on_accept=on_accept,
        on_change=on_change,
        placeholder_text="Password",
        visibility=False,  # ••••••••
        width_chars=20,
    )
    reset_entry(entry)

    overlay = widgets.Box(
        css_classes=["lock-screen-overlay"],
        halign="center",
        spacing=24,
        valign="center",
        vertical=True,
        child=[entry],
    )

    def on_open(_window, _):
        entry.text = ""
        # if monitor_id == 0:
        # entry.grab_focus()
        # utils.exec_timeout(10, lambda: entry.grab_focus())
        pass

    return widgets.Window(
        anchor=["top", "left", "right", "bottom"],
        css_classes=["lock-screen"],
        exclusivity="ignore",  # Completely ignore other surfaces.
        kb_mode="exclusive",
        layer="overlay",
        monitor=monitor_id,
        namespace=namespace(connector),
        setup=lambda self: self.connect("notify::visible", on_open),
        visible=visible,  # Initially not open.
        child=widgets.Overlay(
            overlays=[overlay],
            child=widgets.Box(
                css_classes=["lock-screen-background"],
                hexpand=True,
                vexpand=True,
            ),
        ),
    )


# Functions for controlling the lock screen. ###################################

IS_LOCKED = False


def close_lock_screen(app: IgnisApp):
    global IS_LOCKED
    IS_LOCKED = False
    set_hyprland_mode(Lock.UNLOCK)
    for monitor in utils.get_monitors():
        connector = monitor.get_connector()
        try:
            app.close_window(namespace(connector))
        except Exception as e:
            # Ignore exception if application doesn't exist on monitor.
            print(f"Failed to close lock screen on connector {connector}: {e}")
            pass


def open_lock_screen(app: IgnisApp):
    global IS_LOCKED
    IS_LOCKED = True
    set_hyprland_mode(Lock.LOCK)
    for monitor in utils.get_monitors():
        connector = monitor.get_connector()
        try:
            app.open_window(namespace(monitor.get_connector()))
        except Exception as e:
            # Ignore exception if application doesn't exist on monitor.
            print(f"Failed to open lock screen on connector {connector}: {e}")
            pass


def register_lock_screen(app: IgnisApp):
    # Keep track of windows by connector (monitor).
    windows = {}

    def create_windows(monitors):
        for monitor_id, monitor in enumerate(monitors):
            connector = monitor.get_connector()
            if connector not in windows:
                windows[connector] = create_lock_screen_window(
                    connector,
                    monitor_id,
                    lambda: close_lock_screen(app),
                    visible=IS_LOCKED,
                )

    def destroy_windows(monitors):
        connectors = set(m.get_connector() for m in monitors)
        for connector in list(windows.keys()):
            if connector not in connectors:
                app.close_window(namespace(connector))
                del windows[connector]

    # When a monitor is connected/disconnected, create/destroy a window.
    def adjust_windows(monitors, _a, _b, _c):
        create_windows(monitors)
        destroy_windows(monitors)

    utils.get_monitors().connect("items-changed", adjust_windows)

    create_windows(utils.get_monitors())
