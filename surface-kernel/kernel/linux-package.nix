{
  pkgs,
  lib,
  fetchurl,
  buildLinux,
  linuxPackagesFor,
}:

let
  inherit (builtins) elem;
  inherit (lib) recurseIntoAttrs types versions;

  linuxPackage =
    {
      url ? "mirror://kernel/linux/kernel/v${versions.major version}.x/linux-${version}.tar.xz",
      sha256 ? null,
      src ? (fetchurl { inherit url sha256; }),
      version,
      modDirVersion ? (versions.pad 3 version),
      kernelPatches ? [ ],
      ...
    }@args:
    let
      inherit (builtins) removeAttrs;

      args' = {
        inherit
          src
          version
          modDirVersion
          kernelPatches
          ;
      }
      // removeAttrs args [
        "url"
        "sha256"
      ];
    in
      buildLinux args';

  structuredConfig = kernel_config:
    let
      config_raw = builtins.readFile kernel_config;
      kernelConfigOption = {
        "m" = lib.kernel.module;
        "y" = lib.kernel.yes;
        "n" = lib.kernel.no;
      };
    in
    lib.listToAttrs
      (map (s: {
        name = lib.lists.head (builtins.match "([^=]+)=.*" s);
        value = kernelConfigOption.${lib.lists.head (builtins.match "[^=]+=(.*)" s)};
      })
        (builtins.filter (s: s != "" && ((builtins.match "^#.*" s) == null))
          (lib.splitStringBy (p: c: c == "\n") false config_raw)));

  surfacePatches =
    {
      kernelConfig,
      patchSrc,
      version,
      patchFn,
    }:
    pkgs.callPackage patchFn {
      inherit version patchSrc;
      structuredExtraConfig = structuredConfig kernelConfig;
    };

  versionsOf =
    version:
    # Provides a list of versions that can be used as an enum option for this full version:
    [
      version
      (versions.majorMinor version)
    ];

  versionsOfEnum =
    version:
    # Provide an enum option for versions of this kernel:
    types.enum (versionsOf version);

  isVersionOf =
    kernelVersion: version:
    # Test if the provided version is considered one of the list of versions from above:
    elem kernelVersion (versionsOf version);

in
{
  inherit
    linuxPackage
    surfacePatches
    versionsOf
    isVersionOf
    versionsOfEnum
    ;
}
