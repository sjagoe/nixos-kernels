let
  overrideKernel = pkgs: version: hash:
    let
      inherit (pkgs) lib;

      major = lib.versions.major version;
      minor = lib.versions.minor version;

      kernelFor = version:
        pkgs."linux_${major}_${minor}";
    in
      (kernelFor version).override {
        argsOverride = {
          src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v${major}.x/linux-${version}.tar.xz";
            inherit hash;
          };
          inherit version;
          modDirVersion = version;
        };
      };
in
{
  generatePackages = system: hashes: pkgs:
    let
      inherit (pkgs) lib;
      versions = builtins.attrNames hashes;
      nameKernel = version: "linux_${builtins.replaceStrings ["."] ["_"] (lib.versions.majorMinor version)}";
      hash = version: hashes."${version}";
      kernelsByVersion = builtins.listToAttrs
        (builtins.map
          (version: { name = version; value = overrideKernel pkgs version (hash version); })
          versions);
    in
      (lib.mapAttrs'
        (version: package: { name = nameKernel version; value = package; })
        kernelsByVersion);
}
