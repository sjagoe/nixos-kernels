{
  pkgs,
  version,
  hash
}:

let
  inherit (builtins)
    attrNames;

  inherit (pkgs) lib;

  inherit (lib)
    mkDefault
    mkOption
    types
    versions;

  kernelRelease' = versions.majorMinor version;

  # Fetch the latest linux-surface patches
  linux-surface = pkgs.fetchFromGitHub {
    owner = "sjagoe";
    repo = "linux-surface";
    rev = "a3fa6fa6c51ebb5bcf9731af3ebda7d5cc1dfac0";
    hash = "sha256-KqB3x5RMNgZyT9qHZCZkkwXw3ysEnmCjQjeaNrVgJHw=";
  };

  # Fetch and build the kernel
  inherit (pkgs.callPackage ./kernel/linux-package.nix { })
    linuxPackage
    surfacePatches;
  kernelPatches = surfacePatches {
    inherit version;
    patchFn = ./kernel/${kernelRelease'}/patches.nix;
    patchSrc = linux-surface + "/patches/${kernelRelease'}";
  };
  kernel = linuxPackage {
    inherit kernelPatches;
    inherit version;
    sha256 = hash;
    ignoreConfigErrors = true;
  };

  kernelName = "linux-surface_${lib.strings.replaceStrings ["."] ["_"] kernelRelease'}";
in
{
  ${kernelName} = kernel;
}
