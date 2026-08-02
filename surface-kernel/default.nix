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
    rev = "62b64ef2d4e4f123ff68abbbd7f70b91da75de3d";
    hash = "sha256-7egPj8SvZ0dj/sQV6tiX4a2S2XO94Q9yGx2+GknrLxI=";
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
  kernelPackages = linuxPackage {
    inherit kernelPatches;
    inherit version;
    sha256 = hash;
    ignoreConfigErrors = true;
  };

  kernelName = "linuxPackagesSurface_${lib.strings.replaceStrings ["."] ["_"] kernelRelease'}";
in
{
  ${kernelName} = kernelPackages;
}
