let
  overrideKernel = pkgs: version: hash:
    let
      inherit (pkgs) lib;

      major = lib.versions.major version;
      minor = lib.versions.minor version;
      release = lib.versions.majorMinor version;

      kernelFor = version:
        let
          standardName = "linux_${major}_${minor}";
          hasKernel = pkgs ? "${standardName}";
          testingVersion = lib.versions.majorMinor pkgs.linux_testing.version;
          isTesting = release == testingVersion;
        in
          if (hasKernel) then pkgs.${standardName} else
            if (isTesting) then pkgs.linux_testing else
              throw "Linux ${release} is not available to override from nixpkgs";
    in
      (kernelFor version).override {
        argsOverride = {
          src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v${major}.x/linux-${version}.tar.xz";
            inherit hash;
          };
          inherit version;
          modDirVersion = lib.versions.pad 3 version;
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
