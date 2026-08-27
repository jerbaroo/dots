{
  config,
  pkgs,
  lib,
  doomModule,
  ...
}:
let
  configEl = pkgs.replaceVars ./config.el {
    codeFontName = config.desktop.font.code.name;
    codeBackgroundOpacity = toString (
      builtins.floor (config.desktop.font.code.backgroundOpacity * 100)
    );
    codeFontSize = toString (config.desktop.font.code.size) + ".0";
    colourComment = config.desktop.theme.palette.rosewater.hex;
    colourLineNumber = config.desktop.theme.palette.subtext0.hex;
    colourLineNumberCurrent = config.desktop.theme.palette.peach.hex;
    flavor = config.desktop.theme.flavor;
    paletteOverrides =
      let
        changes = config.desktop.theme.paletteChanges;
      in
      if changes == { } then
        ""
      else
        lib.concatStringsSep "\n" (
          [ ''(load "catppuccin-theme" nil t)'' ]
          ++ lib.mapAttrsToList (name: colour: "(catppuccin-set-color '${name} \"${colour.to}\")") changes
          ++ [ "(catppuccin-reload)" ]
        );
  };
  doomDir = pkgs.runCommandLocal "doom-config" { } ''
    mkdir -p $out
    cp ${./init.el} $out/init.el
    cp ${./packages.el} $out/packages.el
    cp ${configEl} $out/config.el
  '';
in
{
  imports = [ doomModule ];
  home.packages = [ pkgs.fd ];
  programs.doom-emacs = {
    enable = true;
    doomDir = doomDir;
    emacs = pkgs.emacs-pgtk;
    # ghostel and evil-ghostel are the same upstream repo, but they reach us by
    # different routes and drift apart. ghostel is a hand-written nixpkgs
    # package held at a release tag, because building its Zig module needs a
    # fixed-output hash that has to be updated by hand; evil-ghostel is an
    # unpinned MELPA snapshot, so it tracks the repo's default branch. The
    # newer half then calls into functions the older half does not have yet
    # (e.g. `ghostel-alt-screen-p', added after 0.44.0), which surfaces as
    # "Symbol's function definition is void" from ghostel's process filter.
    # Build evil-ghostel out of ghostel's own source so the two always match.
    emacsPackageOverrides = eself: esuper: {
      evil-ghostel = esuper.evil-ghostel.overrideAttrs (_: {
        inherit (esuper.ghostel) src version;
      });
    };
  };
  programs.ripgrep.enable = true;
}
