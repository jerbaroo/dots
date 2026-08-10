{ lib, ... }:
let
  # A curve is tagged by type so each backend emits the right thing: a bezier is
  # four control-point strings; a spring is (mass, stiffness, dampening).
  bezier = points: {
    type = "bezier";
    inherit points;
  };
  spring = mass: stiffness: dampening: {
    type = "spring";
    inherit mass stiffness dampening;
  };
  curves = {
    # Ease-in: starts still, builds speed. For things leaving — they accelerate
    # away rather than drifting off.
    accelerate = bezier [
      "0.3"
      "0"
      "0.8"
      "0.15"
    ];
    # Pulls back slightly before moving off (y1 < 0), an anticipatory wind-up.
    anticipate = bezier [
      "1"
      "-0.1"
      "0.7"
      "0.85"
    ];
    # Apple's spring feel: snaps toward the target with just a whisper of
    # overshoot, then settles smoothly — refined, not a wobble. The numbers give
    # a damping ratio of ~0.78 (dampening / (2·sqrt(stiffness·mass))) and a
    # natural period of ~0.44s; raise dampening for less overshoot, stiffness for
    # a faster snap. Hyprland-only — QML has its own spring type — so keep it off
    # any curve the menu bar consumes.
    apple = spring "1" "200" "22";
    # Ease-out (OutCubic): moves at once, then decelerates evenly onto the
    # target with no overshoot. The honest default for something settling.
    decelerate = bezier [
      "0.215"
      "0.61"
      "0.355"
      "1"
    ];
    # Constant rate. For a transition where easing is imperceptible (a colour, a
    # border) and a curve would only add cost.
    linear = bezier [
      "0"
      "0"
      "1"
      "1"
    ];
    # Decelerate that carries a little past the target and eases back — reads as
    # arriving with mass. The overshoot (y1 > 1) is kept small, so it settles
    # rather than bounces. A bezier stand-in for a spring where a spring can't
    # go (the menu bar's QML).
    overshoot = bezier [
      "0.34"
      "1.08"
      "0.22"
      "1"
    ];
    # Near-instant, then a long soft tail (Material 3 "emphasized decelerate"):
    # covers most of the distance in the first few frames.
    snap = bezier [
      "0.05"
      "0.7"
      "0.1"
      "1"
    ];
    # Ease-in-out: symmetric, for a move that both starts and ends on screen and
    # should not call attention to either end.
    standard = bezier [
      "0.2"
      "0"
      "0"
      "1"
    ];
  };
  animation = lib.types.submodule {
    options = {
      curve = lib.mkOption {
        description = "Which curve from desktop.animation.curves this eases along.";
        type = lib.types.enum (builtins.attrNames curves);
      };
      durationMs = lib.mkOption {
        description = "Canonical duration in milliseconds.";
        type = lib.types.ints.positive;
      };
    };
  };
  # Terse constructor for the defaults below.
  anim = curve: durationMs: { inherit curve durationMs; };
in
{
  options.desktop.animation = {
    colorShift = lib.mkOption {
      default = anim "standard" 200;
      description = "State/border colour easing.";
      type = animation;
    };
    curves = lib.mkOption {
      default = curves;
      description = "The curve vocabulary (each tagged bezier or spring).";
      readOnly = true;
      type = lib.types.attrsOf lib.types.attrs;
    };
    fadeIn = lib.mkOption {
      default = anim "decelerate" 150;
      description = "Opacity rising (fades in; second half of a content cross-fade).";
      type = animation;
    };
    fadeOut = lib.mkOption {
      default = anim "accelerate" 100;
      description = "Opacity falling (fades out; leading half of a content cross-fade).";
      type = animation;
    };
    growX = lib.mkOption {
      default = anim "overshoot" 250;
      description = "An element changing width.";
      type = animation;
    };
    growY = lib.mkOption {
      default = anim "overshoot" 280;
      description = "An element changing height (menu-bar panel reveal and resize).";
      type = animation;
    };
    transitionX = lib.mkOption {
      default = anim "decelerate" 160;
      description = "An element sliding to a new x (menu-bar panel slide, workspace slide).";
      type = animation;
    };
    transitionY = lib.mkOption {
      default = anim "decelerate" 280;
      description = "An element sliding to a new y (special-workspace slide).";
      type = animation;
    };
    windowIn = lib.mkOption {
      default = anim "apple" 300;
      description = "A surface/window materialising (Hyprland windows/layers in).";
      type = animation;
    };
    windowMove = lib.mkOption {
      default = anim "apple" 300;
      description = "A window moving, dragging or tiling to a new position.";
      type = animation;
    };
    windowOut = lib.mkOption {
      default = anim "accelerate" 200;
      description = "A surface/window dismissing.";
      type = animation;
    };
  };
}
