{
  config,
  lib,
  pkgs,
  ...
}:
let
  colour = name: config.desktop.theme.palette.${name}.hex;
in
{
  home.packages = with pkgs; [ gitu ];
  # Required to avoid '[bat warning]: Unknown theme' when using delta.
  # But bat is also just great.
  programs.bat = {
    config.theme = "desktop";
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batgrep
      batman
      batpipe
      batwatch
      prettybat
    ];
    themes.desktop.src = import ./git-theme.nix {
      inherit lib pkgs;
      palette = config.desktop.theme.palette;
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      dark = config.desktop.theme.flavor != "latte";
      file-decoration-style = "${colour "blue"} ul";
      file-style = "${colour "blue"} bold";
      hunk-header-decoration-style = "${colour "surface2"} box";
      hunk-header-file-style = "${colour "blue"} bold";
      hunk-header-line-number-style = colour "peach";
      hunk-header-style = "file line-number ${colour "text"}";
      keep-plus-minus-markers = true;
      light = config.desktop.theme.flavor == "latte";
      line-numbers = true;
      line-numbers-left-style = colour "overlay0";
      line-numbers-minus-style = colour "red";
      line-numbers-plus-style = colour "green";
      line-numbers-right-style = colour "overlay0";
      line-numbers-zero-style = colour "overlay0";
      minus-emph-style = "syntax ${colour "surface1"}";
      minus-style = "syntax ${colour "surface0"}";
      navigate = true;
      plus-emph-style = "syntax ${colour "surface2"}";
      plus-style = "syntax ${colour "mantle"}";
      syntax-theme = "desktop";
      true-color = "always";
      whitespace-error-style = "${colour "red"} reverse";
      zero-style = "syntax normal";
    };
  };
  programs.git = {
    enable = true;
    settings = {
      branch.sort = "committerdate";
      color.diff = {
        context = colour "text";
        frag = "${colour "mauve"} bold";
        meta = "${colour "blue"} bold";
        new = colour "green";
        newMoved = colour "green";
        old = colour "red";
        oldMoved = colour "peach";
        whitespace = "${colour "red"} reverse";
      };
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
