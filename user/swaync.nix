{
  # TODO remove this module.
  services.swaync = {
    enable = false;
    settings = {
      timeout-critical = 10;
      widgets = [
        "title"
        "notifications"
      ];
    };
  };
}
