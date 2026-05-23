{ pkgs, ... }:
{
  programs.gamemode.enable = true;
  programs.steam = {
    dedicatedServer.openFirewall = true;
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
  };
}
