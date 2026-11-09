{
  pkgs,
  version,
  release,
  hash,
  name,
}:

let
  linux-surface-source = builtins.fromJSON (builtins.readFile ./linux-surface.json);

  source = if linux-surface-source.${name} == null then
    linux-surface-source.lts
      else linux-surface-source.${name};

  # Fetch the latest linux-surface patches
  linux-surface = pkgs.fetchFromGitHub {
    inherit (source) owner repo rev hash;
  };

  # Fetch and build the kernel
  inherit (pkgs.callPackage ./kernel/linux-package.nix { })
    linuxPackage
    surfacePatches;
  kernelPatches = surfacePatches {
    inherit version;
    patchFn = ./kernel/${release}/patches.nix;
    patchSrc = linux-surface + "/patches/${release}";
  };
  kernel = linuxPackage {
    inherit kernelPatches;
    inherit version;
    sha256 = hash;
    ignoreConfigErrors = true;
  };

in
kernel
