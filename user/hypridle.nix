{ lockTimeout, pkgs }:
let
  lockingCountdown =
    n: "fish -c 'notify_countdown -f ${lockingPath} -t ${toString n} -m \'Locking in {} seconds\''";
  lockingPath = "/tmp/hypr_locking";
in
{
  services.hypridle = {
    # TODO move to another module.
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
          on-timeout = "touch ${lockingPath}; " + lockingCountdown 10;
          timeout = lockTimeout - 10;
        }
        # Lock.
        {
          on-timeout = "loginctl lock-session";
          timeout = lockTimeout;
        }
        # Screen off.
        {
          on-resume = "hyprctl dispatch dpms on";
          on-timeout = "hyprctl dispatch dpms off";
          timeout = lockTimeout + 60;
        }
        # Sleep.
        {
          on-timeout = "systemctl suspend";
          timeout = lockTimeout + (60 * 5);
        }
      ];
    };
  };
}
