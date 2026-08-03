{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      kernelHashes = (builtins.fromJSON (builtins.readFile ./kernels.json)).hashes;

      mainline = import ./mainline;
      mainlinePackages = builtins.listToAttrs
        (map
          (system:
            let
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
                  "nvidia-x11"
                  "nvidia-kernel-modules"
                  "nvidia-settings"
                ];
              };
            in
            { name = system; value = mainline.generatePackages system kernelHashes pkgs; })
          systems);

      surfaceKernelRelease = "6.18";
      surfaceKernelVersion =
        builtins.elemAt
          (builtins.filter
            (version: (builtins.match "^${lib.escapeRegex surfaceKernelRelease}\.[[:digit:]]+" version) != null)
            (builtins.attrNames kernelHashes))
          0;

      surfacePackages = {
        x86_64-linux = import ./surface-kernel {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          version = surfaceKernelVersion;
          hash = kernelHashes.${surfaceKernelVersion};
        };
      };

      packages = lib.attrsets.recursiveUpdate mainlinePackages surfacePackages;

      runner-label = arch:
        if (arch == "aarch64-linux") then
          "ubuntu-latest-arm" else
            "ubuntu-latest";
    in
      {
        inherit packages;
        ci.build =
          lib.flatten (map
            ({ runs-on, arch, pkgs }:
              map (pkg: { inherit runs-on; build = ".#packages.${arch}.${pkg}"; }) (builtins.attrNames pkgs))
            (lib.mapAttrsToList
              (arch: pkgs: { runs-on = runner-label arch; inherit arch pkgs; })
              packages));
      };
}
