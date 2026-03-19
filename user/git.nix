{ pkgs, ... }:
{
  home.packages = with pkgs; [ gitu ];
  # Required to avoid '[bat warning]: Unknown theme' when using delta.
  # But bat is also just great.
  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batgrep
      batman
      batpipe
      batwatch
      prettybat
    ];
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.line-numbers = true;
  };
  programs.git = {
    enable = true;
    settings = {
      push.autoSetupRemote = true;
      rebase.autoSquash = false;
      user = {
        name = "jerbaroo";
        email = "jerbaroo.work@pm.me";
      };
    };
  };
  programs.git-cliff.enable = true;
  programs.lazygit = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      quitOnTopLevelReturn = true;
    };
  };
}
