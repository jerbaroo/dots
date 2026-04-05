{ pkgs, ... }:

let pathInHome = ".config/kanata/config.kbd";
in {
  hm = { home.file.${pathInHome}.source = ./config.kbd; };
  run = "${pkgs.kanata}/bin/kanata -c ~/${pathInHome}";
}
