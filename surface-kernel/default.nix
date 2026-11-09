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
    owner = "linux-surface";
    repo = "linux-surface";
    rev = "04bf0852b351f0baec394abc95222dfa8fb37d77";
    hash = "sha256-c7HSTXZpbryzTxx4M6s8ohcxKGj7f5zV7EpZXpS4VZQ=";
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
