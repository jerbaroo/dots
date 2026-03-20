import app_launcher
import bar
import lock_screen
import logout_menu
import os
from ignis.css_manager import CssInfoPath, CssManager
from ignis import utils
from ignis.app import IgnisApp

__dir__ = os.path.dirname(os.path.realpath(__file__))
css_path = os.path.join(__dir__, "app.scss")
print(f"CSS path: {css_path}")

app = IgnisApp.get_initialized()
app.reload_on_monitors_change = False

css_manager = CssManager.get_default()
css_manager.apply_css(
    CssInfoPath(
        name="main",
        path=css_path,
        compiler_function=lambda path: utils.sass_compile(path=path),
        priority="user",
    )
)

app_launcher.app_launcher(app)
lock_screen.register_lock_screen(app)
for monitor in range(utils.get_n_monitors()):
    bar.bar(monitor)
    logout_menu.logout_menu(app, monitor)
