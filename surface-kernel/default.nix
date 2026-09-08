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
    rev = "de402513708b2daf1e22785e0ebc57c9b2409327";
    hash = "sha256-kTz38JpIYeDkBgLn9fMDmMIJtIj6JzUulCkHI79XlpU=";
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
