{
  lib,
  palette,
  pkgs,
}:
let
  colour = name: palette.${name}.hex;
  syntaxColours = {
    "comment" = "overlay0";
    "constant" = "lavender";
    "entity.name.function" = "flamingo";
    "entity.name.tag" = "peach";
    "entity.name.type, entity.other.inherited-class" = "blue";
    "invalid" = "red";
    "keyword, storage" = "peach";
    "keyword.operator" = "sky";
    "markup.deleted" = "red";
    "markup.heading" = "blue";
    "markup.inserted" = "green";
    "markup.raw, string" = "rosewater";
    "punctuation" = "overlay2";
    "support.function" = "peach";
    "support.type" = "blue";
    "variable" = "text";
    "variable.other.member, entity.other.attribute-name" = "lavender";
  };
in
pkgs.writeText "desktop.tmTheme" (
  lib.generators.toPlist { escape = true; } {
    name = "desktop";
    settings = [
      {
        settings = {
          background = colour "base";
          caret = colour "rosewater";
          foreground = colour "text";
          selection = colour "surface1";
        };
      }
    ]
    ++ lib.mapAttrsToList (scope: name: {
      inherit scope;
      settings.foreground = colour name;
    }) syntaxColours;
  }
)
