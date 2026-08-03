{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      kernelHashes = (builtins.fromJSON (builtins.readFile ./kernels.json)).hashes;

      mainline = import ./mainline;
      mainlinePackages = builtins.listToAttrs
        (map
          (system:
            let
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
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
            (version: (builtins.match "^${nixpkgs.lib.escapeRegex surfaceKernelRelease}\.[[:digit:]]+" version) != null)
            (builtins.attrNames kernelHashes))
          0;

      surfacePackages = {
        x86_64-linux = import ./surface-kernel {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          version = surfaceKernelVersion;
          hash = kernelHashes.${surfaceKernelVersion};
        };
      };

      packages = nixpkgs.lib.attrsets.recursiveUpdate mainlinePackages surfacePackages;
    in
      {
        inherit packages;
        ci.build = nixpkgs.lib.mapAttrsToList (name: pkg: ".#packages.x86_64-linux.${name}") packages.x86_64-linux;
      };
}
