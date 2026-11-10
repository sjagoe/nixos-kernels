{
  pkgs,
  lib,
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

  patchFn = { patchSrc, version, structuredExtraConfig }:
    let
      patchFilenames =
        builtins.filter (s: (builtins.match ".*\.patch$" s != null))
          (map (i: i.name)
            (builtins.filter (a: a.value == "regular")
              (lib.attrsToList (builtins.readDir patchSrc))));

      mkPatch = filename:
        {
          name = "ms-surface/${lib.lists.head (builtins.match "^(.*)\.patch$" filename)}";
          patch = patchSrc + "/${filename}";
        };

      patches = map mkPatch (builtins.sort (a: b: a < b) patchFilenames);
    in
      [
        {
          name = "microsoft-surface-patches-linux-${version}";
          patch = null;
          inherit structuredExtraConfig;
        }
      ] ++ patches;

  # Fetch and build the kernel
  inherit (pkgs.callPackage ./kernel/linux-package.nix { })
    linuxPackage
    surfacePatches;
  kernelPatches = surfacePatches {
    inherit version patchFn;
    patchSrc = linux-surface + "/patches/${release}";
    kernelConfig = linux-surface + "/configs/surface-${release}.config";
  };
  kernel = linuxPackage {
    inherit kernelPatches;
    inherit version;
    sha256 = hash;
    ignoreConfigErrors = true;
  };

in
kernel
