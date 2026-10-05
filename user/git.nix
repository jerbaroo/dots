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
    options = {
      line-numbers = true;
      navigate = true;
    };
  };
  programs.git = {
    enable = true;
    settings = {
      branch.sort = "committerdate";
      column = {
        ui = "auto";
        verbose = true;
      };
      core.excludesfile = "~/.gitignore";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        colorWords = true;
        mnemonicPrefix = true;
        renames = true;
        wordRegex = ''\w+|.'';
      };
      fetch = {
        all = true;
        prune = true;
        pruneTags = true;
      };
      help.autocorrect = "prompt";
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      pull.rebase = true;
      push = {
        autoSetupRemote = true;
        followTags = true;
      };
      rebase = {
        autoSquash = false;
        autoStash = true;
        updateRefs = true;
      };
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      tag.sort = "version:refname";
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
