{ config, pkgs, ... }:
let
  lockingCountdown =
    n: "fish -c 'notify_countdown -f ${lockingPath} -t ${toString n} -m \'Locking in {} seconds\''";
  lockingPath = "/tmp/hypr_locking";
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Screen off after entering sleep.
        after_sleep_cmd = "hyprctl dispatch dpms on";
        # Lock before entering sleeping.
        before_sleep_cmd = "loginctl lock-session";
        # Lock if not already locked.
        # TODO ${pkgs.playerctl}/bin/playerctl pause
        lock_cmd = "pidof os-lock || os-lock "; # TODO
      };
      listener = [
        # Locking notification.
        {
          on-resume = "rm ${lockingPath}";
          on-timeout = config.desktop.lock.unlessNoLock ("touch ${lockingPath}; " + lockingCountdown 10);
          timeout = config.desktop.lock.timeout - 10;
        }
        # Lock.
        {
          on-timeout = config.desktop.lock.unlessNoLock "loginctl lock-session";
          timeout = config.desktop.lock.timeout;
        }
        # Screen off.
        {
          on-resume = "hyprctl dispatch dpms on";
          on-timeout = config.desktop.lock.unlessNoLock "hyprctl dispatch dpms off";
          timeout = config.desktop.lock.timeout + 60;
        }
        # Sleep.
        {
          on-timeout = "systemctl suspend";
          timeout = config.desktop.lock.timeout + (60 * 5);
        }
      ];
    };
  };
}
