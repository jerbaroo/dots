{ pkgs, ... }:

let pathInHome = ".config/kanata/config.kbd";
in {
  hm = { home.file.${pathInHome}.source = ./kanata/config.kbd; };
  run = "${pkgs.kanata}/bin/kanata -c ~/${pathInHome}";
}
