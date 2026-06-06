# This module is taken from:
# https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html
{ lib, pkgs, ... }:
{
  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];
  # Lanzaboote currently replaces the systemd-boot module. This setting is
  # usually set to true in configuration.nix generated at installation time.
  # So we force it to false for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    autoEnrollKeys = {
      autoReboot = true;
      enable = true;
    };
    autoGenerateKeys.enable = true;
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
