{ temperature }:
{
  services.hyprsunset = {
    enable = true;
    extraArgs = [
      "-t"
      "${toString temperature}"
    ];
  };
}
