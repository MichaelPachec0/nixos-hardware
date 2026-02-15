{ callPackage, linux_6_18, pkgs, ... }@args:
callPackage ./generic.nix args {
  kernel = linux_6_18;
  patchesFile = ./latest.json;
  experimental = true;
}
