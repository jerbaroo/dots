{
  config,
  os-cli,
  pkgs,
}:
let
  onChange = pkgs.writeShellScript "monitor-on-change" ''
    ${config.desktop.setWallpaperCmd}
    ${os-cli.ui-reload}
  '';
in
{
  inherit onChange;
}
