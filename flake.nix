{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      kernels-json = builtins.fromJSON (builtins.readFile ./kernels.json);
      availableReleases = kernels-json.versions;
      kernelVersions =
        let
          kernelHashes = kernels-json.hashes;
        in
          builtins.listToAttrs
            (map (system: { name = system; value = kernelHashes; }) systems);

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

      generatePackages = system: hashes:
        let
          pkgs = import nixpkgs { inherit system; };
          inherit (pkgs) lib;

          versionCmp = a: b: (builtins.compareVersions a b) > 0;
          selectVersions = kver:
            let
              re = "^${lib.strings.escapeRegex kver}(\..*|$)";
            in
              builtins.sort versionCmp
                (builtins.filter (i: (builtins.match re i) != null)
                  (builtins.attrNames hashes));

          latestVersionFor = kver:
            builtins.elemAt (selectVersions kver) 0;

          versions = builtins.attrNames hashes;
          nameKernel = version: "linux_${builtins.replaceStrings ["."] ["_"] version}";
          hash = version: hashes."${version}";
          kernelsByVersion = builtins.listToAttrs
            (builtins.map
              (version: { name = version; value = overrideKernel pkgs version (hash version); })
              versions);

          latestKernelFor = release:
            let
              version = latestVersionFor release;
            in
              { name = nameKernel "${release}_latest"; value = kernelsByVersion.${version}; };

          latest = builtins.map
            (release: latestKernelFor release)
            availableReleases;
        in
          (lib.mapAttrs'
            (version: package: { name = nameKernel version; value = package; })
            kernelsByVersion) // (builtins.listToAttrs latest);
    in
      {
        packages = builtins.mapAttrs
          (system: versions: generatePackages system versions)
          kernelVersions;
      };
}
