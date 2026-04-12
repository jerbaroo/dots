{
  accent,
  flavor,
  palette,
  pkgs,
  spicetify,
}:
let
in
{
  programs.spicetify =
    let
      spicePkgs = spicetify.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      colorScheme = flavor;
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        keyboardShortcut
      ];
      theme = spicePkgs.themes.catppuccin;
      wayland = true;
    };
}
