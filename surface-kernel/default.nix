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

  linux-surface-source = builtins.fromJSON (builtins.readFile ./linux-surface.json);
  # Fetch the latest linux-surface patches
  linux-surface = pkgs.fetchFromGitHub {
    inherit (linux-surface-source) owner repo rev hash;
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
