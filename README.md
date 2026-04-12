![image](https://github.com/jerbaroo/nixos/assets/6631452/a53036a8-82a4-4287-acfd-e6edaac9eb00)

## Install

### NixOS
- Install NixOS.
- Install this NixOS config:
  - `sudo rm -rf /etc/nixos`
  - `git clone https://github.com/jerbaroo/nixos-config && cd nixos-config`
  - `sudo nixos-generate-config --show-hardware-config > system/hardware-configuration.nix`
  - `sudo nixos-rebuild switch --flake .#nixos`

### Ubuntu
- Install Ubuntu.
- Install home-manager.
- Install this home-manager config:
  - `git clone https://github.com/jerbaroo/nixos-config && cd nixos-config`
  - `home-manager --flake .#jer@nixos switch`
- Add hyprland desktop entry: `/usr/share/wayland-sessions/hyprland.desktop`

``` yaml
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=/home/jer/.nix-profile/bin/start-hyprland --no-nixgl
Type=Application
```

You may need to run `start-hyprland --no-nixgl` from a TTY once.

### Doom Emacs
- `git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs`
- `~/.config/emacs/bin/doom install` (no envvar file)
- If necessary: `rm -rf ~/.emacs.d`

## Develop ignis components
``` bash
ignis quit
ignis init -c ./user/ignis/config.py
```
