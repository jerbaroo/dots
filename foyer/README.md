# Foyer

Foyer is a Hyprland-specific QuickShell-based desktop shell with:
- menu bar
- notifications
- on-screen display
- application launcher

## Install

Foyer can currently only be installed via Home Manager.

1. Add Foyer as an input to your configuration flake:
    ```nix
    inputs.foyer.url = "github:jerbaroo/dots?dir=foyer";
    ```
2. Include the Home Manager module:
    ```nix
    homeConfigurations."your-user" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        inputs.foyer.homeManagerModules.default
        ./home.nix
      ];
    };
    ```
3. Enable Foyer and configure its [options](options.nix). Required options are
   highlighted.
    ```nix
    programs.foyer = {
      accent = "#b4befe";
      font = {
        name = "Cascadia Mono";
        package = pkgs.cascadia-code;
        size = 18;
      };
      actions = {
        audioSettings = lib.getExe pkgs.pwvucontrol; # required
        bluetoothSettings = lib.getExe' pkgs.blueman "blueman-manager"; # required
        lockScreen = lib.getExe pkgs.hyprlock; # required
        systemMonitor = "${lib.getExe pkgs.kitty} ${lib.getExe pkgs.btop}"; # required
      };
      animation = {
        enter = { curve = [ 0.215 0.61 0.355 1 ]; durationMs = 150; };
        exit = { curve = [ 0.215 0.61 0.355 1 ]; durationMs = 100; };
        resize = { curve = [ 0.34 1.08 0.22 1 ]; durationMs = 280; };
        slide = { curve = [ 0.215 0.61 0.355 1 ]; durationMs = 160; };
      };
      backgroundOpacity = 0.35;
      enable = true; # required
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      layout = {
        borderWidthPx = 2;
        cornerRadiusPx = 8;
        gapPx = 16;
      };
      palette = {
        background = "#11111b";
        controlActive = "#313244";
        controlBorder = "#6c7086";
        controlHover = "#45475a";
        danger = "#f38ba8";
        fieldBackground = "#1e1e2e";
        notificationBody = "#f9e2af";
        panelBackground = "#181825";
        text = "#cdd6f4";
        textMuted = "#a6adc8";
      };
      search.port = 1235;
    };
    ```

### Blur

Foyer exports read-only layer namespaces which you can target with blur rules.
Make sure `programs.foyer.backgroundOpacity` is set to a suitable value. Also
pay attention to the `ignore_alpha` value, it should be greater than zero and
less than `programs.foyer.backgroundOpacity`.

#### Hyprland

```nix
wayland.windowManager.hyprland = {
  configType = "lua";
  extraConfig = let
    namespaces = "^(${lib.concatStringsSep "|" (builtins.attrValues config.programs.foyer.layers)})$";
  in ''
    hl.layer_rule({
        match = {
            namespace = ${builtins.toJSON namespaces},
        },
        blur = true,
        ignore_alpha = 0.001,
    })
  '';
};
```

#### Hyprglass

```nix
wayland.windowManager.hyprland.settings.layer_rule = [
  {
    blur = true;
    ignore_alpha = 0.001;
    match.namespace =
      "^(${lib.concatStringsSep "|" (builtins.attrValues config.programs.foyer.layers)})$";
  }
];
```

### Control commands

```bash
foyer launcher toggle
foyer notifications show
foyer notifications hide
foyer bar toggle
```

Each surface supports `show`, `hide`, and `toggle`. These commands control running
instances; they do not start services. Hiding the bar keeps notifications, the
OSD, and awake-mode inhibitors running.

Use `lib.getExe config.programs.foyer.package` in Home Manager keybindings.
The dev shell points `foyer` at the checkout; outside it the command uses
`$XDG_CONFIG_HOME/foyer`. `FOYER_CONFIG_DIR` can select another running config.

### Awake modes

“No sleep” holds a systemd sleep inhibitor. “No lock” also holds a systemd idle
inhibitor, pausing automatic locking and screen-off. Manual locking remains
available. The idle daemon must honour logind idle inhibitors; [hypridle does so
by default](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/) with
`ignore_systemd_inhibit = false`.

### Installed resources

Foyer installs its configuration under `$XDG_CONFIG_HOME/foyer` (normally
`~/.config/foyer`). Its user services are `foyer-bar`, `foyer-launcher`, and
`foyer-server`. Layer namespaces use the `foyer-` prefix and are exported
through `programs.foyer.layers`.

## Development

Run commands from the Foyer directory.

### Development environment

```bash
nix develop
```

Generates development settings automatically and configures the import path.

### Bar and launcher

Run inside `nix develop`; it adds `quickshell/dev-generated` to
`QML_IMPORT_PATH` so QML can find `FoyerConfig` and `Cmds`.

```bash
systemctl --user stop foyer-bar foyer-launcher
quickshell -p quickshell/bar.qml
# In another terminal, enter nix develop first:
quickshell -p quickshell/app_launcher.qml
# From a third dev shell, open the launcher:
foyer launcher show
```

Edit QML in the checkout; no rebuild is needed. After changing
`dev-settings.nix` or templates, run `nix run .#configure-dev` or re-enter the
dev shell. It writes `Config.qml` and `Cmds` under the ignored
`quickshell/dev-generated/` directory. Production files are unaffected. The
launcher also needs the search server below.

### Tests and linting

```bash
python cli.py --help
cargo test --manifest-path foyer-server/Cargo.toml
cargo clippy --manifest-path foyer-server/Cargo.toml
```

### Formatting

```bash
qmlformat -i quickshell/bar/HoverPanel.qml
nixfmt configure-dev.nix defaults.nix dev-settings.nix flake.nix generate-settings.nix home-manager.nix options.nix
```

### Search server

```bash
systemctl --user stop foyer-server
cargo run --manifest-path foyer-server/Cargo.toml -- --port 1235
# After exiting the development server:
systemctl --user start foyer-server
```

Server defaults to port `1235`.

### Wi-Fi interface

```bash
quickshell -p quickshell/nmtui.qml
```

### Logs and services

```bash
journalctl --user -u foyer-server -f
journalctl --user -u foyer-bar -f
systemctl --user restart foyer-bar foyer-launcher
```
