import re
import subprocess
from ignis import widgets
from ignis.app import IgnisApp
from ignis.services.applications import Application, ApplicationsService

app_service = ApplicationsService.get_default()
app_launcher_name = "ignis-app-launcher"


def close_launcher(ignis_app: IgnisApp):
    ignis_app.close_window(app_launcher_name)


class AppItem(widgets.Button):

    def __init__(self, app: Application, ignis_app):
        self.app = app
        self.ignis_app = ignis_app

        super().__init__(
            on_click=lambda x: self.launch(),
            child=widgets.Box(
                css_classes=["app-launcher-app"],
                child=[
                    widgets.Icon(image=app.icon, pixel_size=48),
                    widgets.Label(
                        ellipsize="end",
                        label=app.name,
                        max_width_chars=30,
                        css_classes=["app-launcher-app-label"],
                    ),
                ],
            ),
        )

    def launch(self):
        exec_string = re.sub(r"%\S*", "", self.app.exec_string)
        print(f"Launching {exec_string}")
        close_launcher(self.ignis_app)
        subprocess.Popen(exec_string, shell=True)


def app_launcher(ignis_app: IgnisApp) -> widgets.Window:

    def on_change(x, app_list):
        apps = app_service.search(app_service.apps, x.text)
        app_list.child = [AppItem(app, ignis_app) for app in apps[:6]]

    def on_accept(x, app_list):
        if len(app_list.child) >= 1:
            app_list.child[0].launch()

    app_list = widgets.Box(
        css_classes=["app-launcher-list"],
        vertical=True,
        child=[],
    )

    entry = widgets.Entry(
        css_classes=["app-launcher-entry"],
        hexpand=True,
        on_accept=lambda x: on_accept(x, app_list),
        on_change=lambda x: on_change(x, app_list),
        placeholder_text="Search",
    )

    search = widgets.Box(
        css_classes=["app-launcher-search"],
        child=[
            widgets.Icon(
                css_classes=["app-launcher-search-icon"],
                icon_name="system-search-symbolic",
                pixel_size=32,
            ),
            entry,
        ],
    )

    main_box = widgets.Box(
        css_classes=["app-launcher-main"],
        halign="center",
        valign="center",
        vertical=True,
        child=[search, app_list],
    )

    def on_open(window):
        # if not window.visible:
        #     return
        entry.text = ""
        entry.grab_focus()

    return widgets.Window(
        anchor=["top", "right", "bottom", "left"],
        css_classes=["app-launcher"],
        namespace=app_launcher_name,
        kb_mode="on_demand",
        setup=lambda self: self.connect("notify::visible", lambda x, y: on_open(self)),
        popup=True,  # Close on ESC.
        visible=False,  # Initially hidden.
        child=widgets.Overlay(
            overlays=[main_box],
            child=widgets.Button(
                css_classes=["app-launcher-overlay"],
                hexpand=False,
                on_click=lambda x: close_launcher(ignis_app),
                style="background: transparent;",
                vexpand=False,
            ),
        ),
    )
